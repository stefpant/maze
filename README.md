# MAZES
Perfect and Braid mazes in haskell

Maze construction using kruskal algorithm,then for braid search and remove dead ends.

## Installing ghci and load module(in terminal)
* sudo apt-get install haskell-platform
* ghci 
* :load maze

## Examples
1. to show a Perfect Maze 5x6: **putStr (showMaze (kruskal (makeMaze 5 6)) [])**
2. to show a Braid Maze 8x5: **putStr (showMaze (braid (kruskal (makeMaze 8 5))) [])**

## Showing a solved maze
### putStr (showSolvedMaze flag width height (x1,y1) (x2,y2)
* flag: 0->perfect maze, 1->braid maze (else error)
* (x1,y1): starting point(S)
* (x2,y2): final point(F)

## Examples with solved mazes
* for a 5x5 perfect maze and S=(0,0) and F=(4,4)
   -    **putStr (showSolvedMaze 0 5 5 (0,0) (4,4))**

* for a 8x5 braid maze and S=(0,0) and F=(7,4)
   -    **putStr (showSolvedMaze 1 8 5 (0,0) (7,4))**
