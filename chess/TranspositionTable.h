// TranspositionTable.h
// Chess
//
// Tables de Transposition
// Utilise les clés Zobrist pour stocker/récupérer les positions évaluées

#import <Foundation/Foundation.h>
#import "Move.h"

NS_ASSUME_NONNULL_BEGIN


// Types de nœuds dans l'arbre de recherche
typedef NS_ENUM(uint8_t, TTNodeType) {
    TT_EXACT       = 0,  // Score exact (PV node, recherche complète)
    TT_LOWER_BOUND = 1,  // Fail-high (beta cutoff) : score >= valeur stockée
    TT_UPPER_BOUND = 2   // Fail-low (alpha cutoff) : score <= valeur stockée
};


// Entrée de la table de transposition
typedef struct {
    uint64_t key;           // Clé Zobrist (64 bits complets pour détection collision)
    int16_t  score;         // Score de la position (int16 suffit : [-32768, 32767])
    int16_t  bestMoveEncoded; // Coup encodé : fromSq | (toSq << 6) | (flags << 12)
    uint8_t  depth;         // Profondeur de recherche restante
    uint8_t  nodeType;      // Type de nœud (TTNodeType)
    uint8_t  generation;    // Génération pour le scheme de remplacement
    uint8_t  padding;       // Alignement mémoire (struct = 16 bytes)
} TTEntry;


// Statistiques de la table
typedef struct {
    uint64_t probes;        // Nombre de consultations
    uint64_t hits;          // Nombre de hits (trouvé et utilisable)
    uint64_t collisions;    // Nombre de collisions détectées
    uint64_t stores;        // Nombre d'écritures
    uint64_t overwrites;    // Nombre de remplacements
} TTStats;



// Classe TranspositionTable
@interface TranspositionTable : NSObject

   // ----------------------------------------------------------------------------
   // Initialisation
   - (instancetype)initWithSizeMB:(size_t)sizeMB;

   // ----------------------------------------------------------------------------
   // Opérations principales
   // Consulter la table (retourne NULL si non trouvé ou inutilisable)
   // Si bestMove n'est pas NULL, il sera rempli avec le meilleur coup décodé
   - (TTEntry * _Nullable)probe:(uint64_t)zobristKey
                       bestMove:(Move * _Nullable * _Nullable)outBestMove;

   // Stocker une position dans la table
   - (void)store:(uint64_t)zobristKey
           score:(int)score
           depth:(int)depth
        nodeType:(TTNodeType)nodeType
        bestMove:(Move * _Nullable)bestMove;

   // ----------------------------------------------------------------------------
   // Gestion
   // Vider la table (nouveau jeu, nouvelle analyse)
   - (void)clear;

   // Incrémenter la génération (début de nouvelle recherche)
   - (void)newGeneration;

   // ----------------------------------------------------------------------------
   // Statistiques
   // Obtenir les statistiques
   - (TTStats)getStats;

   // Taux de hits (en pourcentage)
   - (double)hitRate;

   // Nombre d'entrées utilisées (approximatif)
   - (size_t)entriesUsed;

   // Taux de remplissage (en pourcentage)
   - (double)fillRate;

   // Afficher les statistiques (pour debug)
   - (void)printStats;

@end

NS_ASSUME_NONNULL_END
