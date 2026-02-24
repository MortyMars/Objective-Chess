// TranspositionTable.m
// Chess
//

#import "TranspositionTable.h"
#import <stdlib.h>  // Pour malloc/free
#import <string.h>  // Pour memset

// ============================================================================
// Macros de debug
// ============================================================================
// #define DEBUG_TT  // Décommenter pour logs verbeux

#ifdef DEBUG_TT
    #define LOG_TT(...) NSLog(__VA_ARGS__)
#else
    #define LOG_TT(...)
#endif

// ============================================================================
// Constantes
// ============================================================================
#define TT_ENTRY_SIZE sizeof(TTEntry)  // 16 bytes par entrée

// Score invalide pour détection d'entrée vide
#define SCORE_NONE INT16_MIN

// ============================================================================
// Interface privée
@interface TranspositionTable () {
   @public
       TTEntry     *table;         // Pointeur vers le tableau d'entrées
       size_t      numEntries;     // Nombre total d'entrées
       size_t      indexMask;      // Masque pour calcul d'index (numEntries - 1)
       uint8_t     generation;     // Génération actuelle
       TTStats     stats;          // Statistiques
   }
@end

// ============================================================================
// Implémentation
@implementation TranspositionTable

   // ----------------------------------------------------------------------------
   // Initialisation
   - (instancetype)initWithSizeMB:(size_t)sizeMB
   {
       self = [super init];
       if (self) {
           // Calculer le nombre d'entrées
           size_t totalBytes = sizeMB * 1024 * 1024;
           numEntries = totalBytes / TT_ENTRY_SIZE;
           
           // Arrondir à la puissance de 2 inférieure pour masque efficace
           // Ex: si numEntries = 10000000, on prend 8388608 (2^23)
           size_t powerOf2 = 1;
           while (powerOf2 * 2 <= numEntries) {
               powerOf2 *= 2;
           }
           numEntries = powerOf2;
           indexMask = numEntries - 1;
           
           // Allouer la mémoire (alignée pour performance)
           table = (TTEntry *)calloc(numEntries, TT_ENTRY_SIZE);
           
           if (!table) {
               // Échec allocation mémoire
               return nil;
           }
           
           generation = 0;
           memset(&stats, 0, sizeof(TTStats));
           
           NSLog(@"✅ TranspositionTable créée:");
           NSLog(@"   Taille demandée: %zu MB", sizeMB);
           NSLog(@"   Taille réelle: %.2f MB", (numEntries * TT_ENTRY_SIZE) / (1024.0 * 1024.0));
           NSLog(@"   Nombre d'entrées: %zu", numEntries);
       }
       return self;
   }

   // ----------------------------------------------------------------------------
   // Deallocation
   - (void)dealloc
   {
       if (table) {
           free(table);
           table = NULL;
       }
   }

   // ----------------------------------------------------------------------------
   // Calcul de l'index dans la table
   - (size_t)indexForKey:(uint64_t)key
   {
       // Utiliser les bits de poids fort pour meilleure distribution
       return (size_t)((key >> 32) & indexMask);
   }

   // ----------------------------------------------------------------------------
   // Encodage/décodage de Move
   - (int16_t)encodeMove:(Move *)move
   {
       if (!move) return 0;
       
       // Format: fromSq (6 bits) | toSq (6 bits) | flags (4 bits)
       // flags: bit 0=capture, bit 1=castle, bit 2=enPassant, bit 3=promotion
       int16_t encoded = 0;
       
       encoded |= (move.fromSquare & 0x3F);           // bits 0-5
       encoded |= ((move.toSquare & 0x3F) << 6);      // bits 6-11
       
       uint8_t flags = 0;
       if (move.isCapture)   flags |= 0x1;
       if (move.isCastling)  flags |= 0x2;
       if (move.isEnPassant) flags |= 0x4;
       if (move.isPromotion) flags |= 0x8;
       
       encoded |= (flags << 12);                       // bits 12-15
       
       return encoded;
   }

   - (Move * _Nullable)decodeMove:(int16_t)encoded
   {
       if (encoded == 0) return nil;
       
       int fromSq = encoded & 0x3F;
       int toSq = (encoded >> 6) & 0x3F;
       
       int fx = fromSq % 8;
       int fy = fromSq / 8;
       int tx = toSq % 8;
       int ty = toSq / 8;
       
       Move *move = [Move newMoveFromX:fx Y:fy ToNx:tx Ny:ty];
       
       uint8_t flags = (encoded >> 12) & 0xF;
       move.isCapture   = (flags & 0x1) != 0;
       move.isCastling  = (flags & 0x2) != 0;
       move.isEnPassant = (flags & 0x4) != 0;
       move.isPromotion = (flags & 0x8) != 0;
       
       return move;
   }

   // ----------------------------------------------------------------------------
   // Probe : Consultation de la table
   - (TTEntry * _Nullable)probe:(uint64_t)zobristKey
                       bestMove:(Move * _Nullable * _Nullable)outBestMove
   {
       stats.probes++;
       
       size_t index = [self indexForKey:zobristKey];
       TTEntry *entry = &table[index];
       
       // Entrée vide ?
       if (entry->key == 0) {
           LOG_TT(@"TT probe: MISS (entrée vide) key=%llx", zobristKey);
           if (outBestMove) *outBestMove = nil;
           return NULL;
       }
       
       // Collision détectée ?
       if (entry->key != zobristKey) {
           stats.collisions++;
           LOG_TT(@"TT probe: COLLISION key=%llx stored=%llx", zobristKey, entry->key);
           if (outBestMove) *outBestMove = nil;
           return NULL;
       }
       
       // Hit !
       stats.hits++;
       LOG_TT(@"TT probe: HIT key=%llx depth=%d score=%d type=%d",
              zobristKey, entry->depth, entry->score, entry->nodeType);
       
       // Décoder le meilleur coup si demandé
       if (outBestMove) {
           *outBestMove = [self decodeMove:entry->bestMoveEncoded];
       }
       
       return entry;
   }

   // ----------------------------------------------------------------------------
   // Store : Stockage dans la table
   - (void)store:(uint64_t)zobristKey
           score:(int)score
           depth:(int)depth
        nodeType:(TTNodeType)nodeType
        bestMove:(Move * _Nullable)bestMove
   {
       stats.stores++;
       
       size_t index = [self indexForKey:zobristKey];
       TTEntry *entry = &table[index];
       
       // Scheme de remplacement : "depth-preferred with generation"
       // Remplacer si:
       // 1. Entrée vide (key == 0)
       // 2. Même position (key == zobristKey)
       // 3. Ancienne génération ET profondeur <= nouvelle profondeur
       // 4. Même génération MAIS profondeur inférieure
       
       BOOL shouldReplace = NO;
       
       if (entry->key == 0) {
           // Entrée vide
           shouldReplace = YES;
       }
       else if (entry->key == zobristKey) {
           // Même position : toujours remplacer si profondeur >= ou nouvelle génération
           shouldReplace = (depth >= entry->depth) || (generation != entry->generation);
       }
       else {
           // Collision : remplacer si ancienne génération ou profondeur très supérieure
           if (entry->generation != generation) {
               shouldReplace = YES;
           }
           else if (depth >= entry->depth + 3) {  // Seuil de remplacement
               shouldReplace = YES;
           }
       }
       
       if (shouldReplace) {
           if (entry->key != 0 && entry->key != zobristKey) {
               stats.overwrites++;
               LOG_TT(@"TT store: OVERWRITE old_key=%llx new_key=%llx", entry->key, zobristKey);
           }
           
           entry->key = zobristKey;
           entry->score = (int16_t)score;
           entry->depth = (uint8_t)depth;
           entry->nodeType = (uint8_t)nodeType;
           entry->generation = generation;
           entry->bestMoveEncoded = [self encodeMove:bestMove];
           
           LOG_TT(@"TT store: key=%llx depth=%d score=%d type=%d",
                  zobristKey, depth, score, nodeType);
       }
       else {
           LOG_TT(@"TT store: REJECTED (depth too low) key=%llx", zobristKey);
       }
   }

   // ----------------------------------------------------------------------------
   // Clear : Vider la table
   - (void)clear
   {
       memset(table, 0, numEntries * TT_ENTRY_SIZE);
       memset(&stats, 0, sizeof(TTStats));
       generation = 0;
       NSLog(@"🗑️ TranspositionTable cleared");
   }

   // ----------------------------------------------------------------------------
   // New Generation : Incrémenter la génération
   - (void)newGeneration
   {
       generation++;
       if (generation == 0) generation = 1;  // Éviter 0 (signifie "vide")
       
       LOG_TT(@"📊 TT nouvelle génération: %d", generation);
   }

   // ----------------------------------------------------------------------------
   // Statistiques
   - (TTStats)getStats
   {
       return stats;
   }

   - (double)hitRate
   {
       if (stats.probes == 0) return 0.0;
       return (double)stats.hits * 100.0 / (double)stats.probes;
   }

   - (size_t)entriesUsed
   {
       // Échantillonnage rapide (check 1000 entrées espacées)
       size_t sampleSize = 1000;
       size_t step = numEntries / sampleSize;
       if (step == 0) step = 1;
       
       size_t used = 0;
       for (size_t i = 0; i < numEntries; i += step) {
           if (table[i].key != 0) used++;
       }
       
       // Extrapoler
       return (used * numEntries) / (numEntries / step);
   }

   - (double)fillRate
   {
       return (double)[self entriesUsed] * 100.0 / (double)numEntries;
   }

   - (void)printStats
   {
       NSLog(@"📊 ===== TranspositionTable Stats =====");
       NSLog(@"   Taille: %.1f MB (%zu entrées)",
             (numEntries * TT_ENTRY_SIZE) / (1024.0 * 1024.0), numEntries);
       NSLog(@"   Probes: %llu", stats.probes);
       NSLog(@"   Hits: %llu (%.1f%%)", stats.hits, [self hitRate]);
       NSLog(@"   Collisions: %llu", stats.collisions);
       NSLog(@"   Stores: %llu", stats.stores);
       NSLog(@"   Overwrites: %llu", stats.overwrites);
       NSLog(@"   Fill rate: %.1f%%", [self fillRate]);
       NSLog(@"   Génération: %d", generation);
       NSLog(@"=====================================");
   }

@end
