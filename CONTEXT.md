# Gliński — Glossary

Use these names in code, tests and docs.

| Term | Meaning |
|---|---|
| **Cell** | One of the 91 hexagons. Not "square". |
| **File** | A vertical column of cells, `a–l` without `j` (11 files). |
| **Rank** | Numbered `1–11`; ranks bend 60° at file `f`. |
| **Notation** | Cell name like `f6`; used only at the edges (UI, move list, tests). |
| **Axial coordinate** | Internal `(q, r)` hex coordinate used by the engine. |
| **Orthogonal** | Through a cell edge (6 directions). Rook moves. |
| **Diagonal** | Between two cells, through a vertex (6 directions). Bishop moves. |
| **Starting cell** | A cell where a pawn of a given colour starts; any own pawn on one may double-step. |
| **Promotion cell** | Last cell of a file in the pawn's forward direction. |
| **Pending promotion** | A pawn move awaiting the player's choice of Q/R/B/N. |
| **Halfmove clock** | Plies since the last capture or pawn move (50-move rule). |
| **Ply** | One player's move. |
| **Game state** | Engine value: board, side to move, history, clocks, result. |
| **State / Intent** | MVI feature state and user intents in `GlinskiFeature`. |
| **Stalemate score** | ¾ to the stalemating side, ¼ to the stalemated side. |
| **Perft** | Count of leaf positions at depth N; validates move generation. |
