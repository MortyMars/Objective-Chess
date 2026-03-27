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
    uint64_t key;             // Clé Zobrist (64 bits complets pour détection collision)
    int32_t  score;           // Score de la position (int32 nécessaire pour scores PeSTO/mat (> ±32767)
    int16_t  bestMoveEncoded; // Coup encodé : fromSq | (toSq << 6) | (flags << 12)
    uint8_t  depth;           // Profondeur de recherche restante
    uint8_t  nodeType;        // Type de nœud (TTNodeType)
    uint8_t  generation;      // Génération pour le scheme de remplacement
    uint8_t  padding;         // Alignement mémoire (struct = 16 bytes)
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

   {
   @public
      TTEntry     *table;         // Pointeur vers le tableau d'entrées
      size_t      numEntries;     // Nombre total d'entrées
      size_t      indexMask;      // Masque pour calcul d'index (numEntries - 1)
      uint8_t     generation;     // Génération actuelle
      TTStats     stats;          // Statistiques
   }

   // INITIALISATION -------------------------------------------------------------
   -(instancetype)initWithSizeMB:(size_t)sizeMB;


   // OPÉRATIONS PRINCIPALES -----------------------------------------------------
   // Consulter la table (retourne NULL si non trouvé ou inutilisable)
   // Si bestMove n'est pas NULL, il sera rempli avec le meilleur coup décodé
   -(TTEntry * _Nullable)probe:(uint64_t)zobristKey
                      bestMove:(Move * _Nullable * _Nullable)outBestMove;

   // Stocker une position dans la table
   -(void)store:(uint64_t)zobristKey
          score:(int)score
          depth:(int)depth
       nodeType:(TTNodeType)nodeType
       bestMove:(Move * _Nullable)bestMove;

   
   // GESTION --------------------------------------------------------------------
   -(void)clear;           // Vider la table (nouveau jeu, nouvelle analyse)
   -(void)newGeneration;   // Incrémenter la génération (début de nouvelle recherche)

   
   // STATISTIQUES ---------------------------------------------------------------
   -(TTStats)getStats;     // Obtenir les statistiques
   -(double)hitRate;       // Taux de hits (en pourcentage)
   -(size_t)entriesUsed;   // Nombre d'entrées utilisées (approximatif)
   -(double)fillRate;      // Taux de remplissage (en pourcentage)
   -(void)printStats;      // Afficher les statistiques (pour debug)

@end

NS_ASSUME_NONNULL_END
