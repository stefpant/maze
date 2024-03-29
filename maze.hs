import System.Random
import System.IO.Unsafe
import Data.Set as Set

data Maze = Maze { cells :: [(Bool, Bool)]  -- [(rightWall, downWall)]
                 , width :: Int
                 , height :: Int
                 }deriving (Show)

rand :: Int -> Int
-- Returns a random integer from 0 to max-1
rand max = unsafePerformIO $ randomRIO (0, max-1)


shuffle :: [a] -> [a]
-- Randomly shuffles a list
shuffle = unsafePerformIO . shuffleM


shuffleM :: [a] -> IO [a]
-- DON'T BOTHER! Helper for shuffle
shuffleM [] = return []

shuffleM n = do {
                r <- fmap (flip mod $ length n) randomIO;
                n1 <- return $ n !! r;
                fmap ((:) n1) $ shuffleM $ (take r n) ++ (drop (r+1) n)
             }

-- ##########################################################################

-- makeMaze here
makeMaze :: Int -> Int -> Maze
makeMaze (w) (h) = Maze (createMaze (w) (h)) (w) (h)


createMaze :: Int -> Int -> [(Bool,Bool)]
createMaze (w) (h) = if h == 0 then []
                     else makeRow (w) ++ createMaze (w) (h-1)

makeRow :: Int -> [(Bool,Bool)]
makeRow w = if w==0 then []
            else (True,True) : makeRow (w-1)


-- for kruskal...
makeCells :: Int -> Int -> [(Int,Int)]
makeCells w h = if h == 0 then []
                else makeCells w (h-1) ++ makeCellsRow w h 

makeCellsRow :: Int -> Int -> [(Int,Int)]
makeCellsRow w h = if w==0 then []
                   else makeCellsRow (w-1) h ++ [(w,h)]

makeWalls :: Int -> Int -> [[(Int,Int)]]
makeWalls w h = if h==0 then []
                else makeWallsRow (w) (h) ++ makeWalls (w) (h-1)

makeWallsRow :: Int -> Int -> [[(Int,Int)]]
makeWallsRow w h = if h==1 then if w==1 then []
                                else [(w,h),(w-1,h)] : makeWallsRow (w-1) (h)
                   else if w==1 then [[(w,h),(w,h-1)]]
                        else [(w,h),(w-1,h)]:[(w,h),(w,h-1)]: makeWallsRow (w-1) (h)

makeSets :: (Eq a) => [a] -> [Set a]
makeSets (x:xs) = if xs == [] then [Set.singleton x]
                  else (Set.singleton x):(makeSets xs)

-- ###
and1 [] = True
and1 (x:xs) = x Prelude.&& and1 xs

map1 f [] = []
map1 f (x:xs) = f x : map1 f xs

True && x = x
False && x = False

sameElems :: (Eq a) => [a] -> Bool
sameElems xs = and1 $ map1 (== head xs) (tail xs)
-- ###


kruskal :: Maze -> Maze
kruskal (Maze _ w h) = Maze (removeWalls walls list1 w h []) w h
                     where walls = (shuffle (makeWalls w h))
                           list1 = (makeSets (makeCells w h))

inSameSet :: [Set (Int,Int)] -> (Int,Int) -> (Int,Int) ->Bool
inSameSet [] _ _ = False
inSameSet (x:xs) t1 t2 = if Set.member t1 x then if Set.member t2 x then True
                                               else False
                       else inSameSet xs t1 t2

findSet :: (Ord a) => [Set a] -> a -> Set a
findSet (x:xs) t = if Set.member t x then x else findSet xs t

restSets :: (Ord a) => [Set a] -> a -> a -> [Set a]
restSets [] t1 t2 = []
restSets (x:xs) t1 t2 = if Set.member t1 x then restSets xs t1 t2
                      else if Set.member t2 x then restSets xs t1 t2
                           else x:restSets xs t1 t2

mergeSets :: (Ord a) => [Set a] -> a -> a -> [Set a]
mergeSets xs t1 t2 = [Set.union (findSet xs t1) (findSet xs t2)] ++ (restSets xs t1 t2)


removeWalls :: [[(Int,Int)]] -> [Set (Int, Int)] ->Int -> Int -> [[(Int,Int)]] -> [(Bool,Bool)]
removeWalls [] xs1 w h xs2 = if w==h then [(True,True)] else (makePerfectMaze xs2 w h)
removeWalls ([(a1,a2),(a3,a4)]:walls) xs1 w h xs2 = if sameElems xs1 then (makePerfectMaze ([(a1,a2),(a3,a4)]:walls ++ xs2) w h)
                                                  else if (inSameSet xs1 (a1,a2) (a3,a4)) then (removeWalls walls xs1 w h ([(a1,a2),(a3,a4)]:xs2))
                                                       else removeWalls walls (mergeSets xs1 (a1,a2) (a3,a4)) w h xs2


emptyMaze :: Int -> Int -> Int -> Int -> [(Bool,Bool)]
emptyMaze w h sw sh = if h>sh then [] else (crER w h sw sh) ++ emptyMaze w (h+1) sw sh


crER :: Int -> Int -> Int -> Int -> [(Bool,Bool)]
crER w h sw sh = if w==sw then if h==sh then [(True,True)]
                              else [(True,False)]
                 else if h==sh then (False,True):crER (w+1) h sw sh
                      else (False,False):crER (w+1) h sw sh

makePerfectMaze :: [[(Int,Int)]] -> Int -> Int -> [(Bool,Bool)]
makePerfectMaze xs w h = createPM xs (emptyMaze 1 1 w h) w


createPM :: [[(Int,Int)]] -> [(Bool,Bool)] -> Int -> [(Bool,Bool)]
createPM [] ys _ = ys
createPM ([(a,b),(c,d)]:xs) ys w = createPM xs (modifiedMZ ys q p w) w
                               where q = (b-1)*w + a
                                     p = (d-1)*w + c


--for k=min(p,q) if |q-p|=1 then 'build' right wall k cell
--         else (if |q-p|=w) 'build' down wall for k cell
modifiedMZ :: [(Bool,Bool)] -> Int -> Int -> Int -> [(Bool,Bool)]
modifiedMZ xs q p w = if q>p then if (q-p)==1 then modMZ xs p 1
                                  else modMZ xs p 2
                      else if (p-q)==1 then modMZ xs q 1
                                  else modMZ xs q 2

modMZ :: [(Bool,Bool)] -> Int -> Int -> [(Bool,Bool)]
modMZ ((x,y):xs) 1 a = if a==1 then (True,y):xs
                     else (x,True):xs

modMZ (x:xs) s a = x:modMZ xs (s-1) a


-- @@@@@@@@@@@@@
-- showMaze
showMaze :: Maze -> [(Int, Int)] -> String
showMaze (Maze xs w h) ys = (crStLine w) ++ (printNextLines xs 0 ys w h)


crStLine :: Int -> String
crStLine w = if w==0 then  "+" ++ "\n"
             else "+---" ++ crStLine (w-1)


printNextLines :: [(Bool,Bool)] -> Int -> [(Int, Int)] -> Int -> Int -> String
printNextLines xs h ys sw sh = if h==sh then "" 
                               else (line1 xs sw h (h*sw) ys) ++ (line2 xs sw (h*sw)) ++ (printNextLines xs (h+1) ys sw sh)


line1 :: [(Bool,Bool)] -> Int -> Int -> Int -> [(Int, Int)] -> String
line1 xs sw h 0 ys = "|" ++ (printline1 xs sw 1 h ys)
line1 (x:xs) sw h coor ys = line1 xs sw h (coor-1) ys


printline1 :: [(Bool,Bool)] -> Int -> Int -> Int -> [(Int, Int)] -> String
printline1 [] _ _ _ _ =  "\n"
printline1 ((a,_):xs) sw w h ys = if w>sw then "\n"
                       else if (elem (w,h+1) ys) then if a==True then " * |" ++ printline1 xs sw (w+1) h ys
                                                  else " *  " ++ printline1 xs sw (w+1) h ys
                            else if a==True then "   |" ++ printline1 xs sw (w+1) h ys
                                 else "    " ++ printline1 xs sw (w+1) h ys


line2 :: [(Bool,Bool)] -> Int -> Int -> String
line2 xs sw 0 = "+" ++ printline2 xs sw 1
line2 (x:xs) sw coor = line2 xs sw (coor-1)


printline2 :: [(Bool,Bool)] -> Int -> Int -> String
printline2 [] _ _ = "\n"
printline2 ((_,b):xs) sw w = if w>sw then "\n"
                             else if b==True then "---+" ++ printline2 xs sw (w+1)
                                  else "   +" ++ printline2 xs sw (w+1)

--for braid..
braid :: Maze -> Maze
braid (Maze xs w h) = Maze (makeBraid xs xs 1 w h) w h


--changes for every y the xs...
makeBraid :: [(Bool,Bool)] -> [(Bool,Bool)] -> Int -> Int -> Int -> [(Bool,Bool)]
makeBraid xs [] _ _ _ = xs
makeBraid xs (y:ys) n w h = makeBraid (modifyMaze xs y n w h) ys (n+1) w h


--checks if y='dead end' then deletes a wall,else returns the xs
modifyMaze :: [(Bool,Bool)] -> (Bool,Bool) -> Int -> Int -> Int -> [(Bool,Bool)]
modifyMaze xs y n w h = if (findWalls  xs y n w h)==3 then (deleteWall xs y n w h)
                        else xs


--checks U-R-D-L walls and returns their sum,if it's 3 then --> 'dead end'
findWalls :: [(Bool,Bool)] -> (Bool,Bool) -> Int -> Int -> Int -> Int
findWalls xs y n w h = (uWall xs y n w h) + (rWall xs y n w h) + (dWall xs y n w h) + (lWall xs y n w h)


uWall :: [(Bool,Bool)] -> (Bool,Bool) -> Int -> Int -> Int -> Int
uWall xs y n w h = if n <= w then 1
                   else (dWall xs (findY xs (n-w)) (n-w) w h)


rWall :: [(Bool,Bool)] -> (Bool,Bool) -> Int -> Int -> Int -> Int
rWall _ (a,_) n w _ = if (a==True) then 1 else 0


dWall :: [(Bool,Bool)] -> (Bool,Bool) -> Int -> Int -> Int -> Int
dWall _ (_,b) _ _ _ = if (b==True) then 1 else 0


lWall :: [(Bool,Bool)] -> (Bool,Bool) -> Int -> Int -> Int -> Int
lWall xs _ n w h = if (mod n w == 1) then 1
                   else (rWall xs (findY xs (n-1)) (n-1) w h) 


--returns the y in pos n
findY :: [(Bool,Bool)] -> Int -> (Bool,Bool)
findY (y:ys) 1 = y
findY (y:ys) n = findY ys (n-1)


--remove one wall from xs
deleteWall :: [(Bool,Bool)] -> (Bool,Bool) -> Int -> Int -> Int -> [(Bool,Bool)]
deleteWall xs y n w h = if (((uWall xs y n w h)==1) Prelude.&& (n>w)) then rmWall xs (n-w) 0 --we can remove the UpWall
                        else if (((rWall xs y n w h)==1) Prelude.&& (mod n w /= 0)) then rmWall xs n 1 --RightWall
                             else if ((dWall xs y n w h)==1) Prelude.&& (n <= (w*(h-1))) then rmWall xs n 0 --DownWall
                                  else rmWall xs (n-1) 1 --here in case to remove LeftWall



--it's same as modMZ with False
--if a=1->remove right else remove down for the elem in s pos
rmWall :: [(Bool,Bool)] -> Int -> Int -> [(Bool,Bool)]
rmWall ((x,y):xs) 1 a = if a==1 then (False,y):xs
                     else (x,False):xs
rmWall (x:xs) s a = x:rmWall xs (s-1) a


-- ###################################################################################################################3
solvePerfect :: Maze -> (Int, Int) -> (Int, Int) -> [(Int, Int)]

                                                  -- START        STOP     PREVIOUS
solvePerfect maze (a,b) (c,d) = solvePerfect1 maze [(a+1,b+1)] [(c+1,d+1)] [(-1,-1)] 0


checkGoal :: Maze -> [(Int, Int)] -> [(Int, Int)] ->  [(Int, Int)] -> Bool
checkGoal (Maze xs width height) [(w,h)] stop previous = if [(w,h)] == stop then True
                                                                            else
                 (if (((dWall xs (findY xs (findN (w,h) width)) (findN (w,h) width) width height)== 0) Prelude.&& (previous /= [(w,h+1)]))
                       then (checkGoal (Maze xs width height) ([(w,h+1)]) stop [(w,h)]) 
                       else False) Prelude.||
                 (if (((rWall xs (findY xs (findN (w,h) width)) (findN (w,h) width) width height)== 0) Prelude.&& (previous /= [(w+1,h)]))
                       then (checkGoal (Maze xs width height) [(w+1,h)] stop [(w,h)]) 
                       else False) Prelude.||
                 (if (((lWall xs (findY xs (findN (w,h) width)) (findN (w,h) width) width height)== 0) Prelude.&& (previous /= [(w-1,h)]))
                       then (checkGoal (Maze xs width height) [(w-1,h)] stop [(w,h)])
                       else False) Prelude.||
                 (if (((uWall xs (findY xs (findN (w,h) width)) (findN (w,h) width) width height)== 0) Prelude.&& (previous /= [(w,h-1)]))
                       then (checkGoal (Maze xs width height) [(w,h-1)] stop [(w,h)])
                       else False)

--recursively maze traversal(Down->Right->Left->Up) to find my goal state
--In the end,the function will return the path [START---->GOAL] in a list!
solvePerfect1 :: Maze -> [(Int, Int)] -> [(Int, Int)] ->  [(Int, Int)] -> Int -> [(Int,Int)]
solvePerfect1 (Maze xs width height) [(w,h)] stop previous flag =
                          if [(w,h)] == stop then stop
                                  else
                                      do
                                     -- check if i can go down
                 if (((dWall xs (findY xs (findN (w,h) width)) (findN (w,h) width) width height)== 0) Prelude.&& (previous /= [(w,h+1)] Prelude.&& mod flag 4==0) Prelude.&& (checkGoal (Maze xs width height) [(w,h+1)] stop [(w,h)])==True )
                   then ((w,h):solvePerfect1 (Maze xs width height) ([(w,h+1)]) stop [(w,h)] 0)
                   else 
                                        -- else check right
                     if (((rWall xs (findY xs (findN (w,h) width)) (findN (w,h) width) width height)== 0) Prelude.&& (previous /= [(w+1,h)] Prelude.&& mod flag 4==1) Prelude.&& (checkGoal (Maze xs width height) [(w+1,h)] stop [(w,h)])==True )
                       then ((w,h):solvePerfect1 (Maze xs width height) [(w+1,h)] stop [(w,h)] 0)
                       else 
                                        -- left
                        if (((lWall xs (findY xs (findN (w,h) width)) (findN (w,h) width) width height)== 0) Prelude.&& (previous /= [(w-1,h)] Prelude.&& mod flag 4==2) Prelude.&& (checkGoal (Maze xs width height) [(w-1,h)] stop [(w,h)])==True )
                          then ((w,h):solvePerfect1 (Maze xs width height) [(w-1,h)] stop [(w,h)] 0)
                          else 
                                        -- up
                            if (((uWall xs (findY xs (findN (w,h) width)) (findN (w,h) width) width height)== 0) Prelude.&& (previous /= [(w,h-1)] Prelude.&& mod flag 4==3) Prelude.&& (checkGoal (Maze xs width height) [(w,h-1)] stop [(w,h)])==True )
                              then ((w,h):solvePerfect1 (Maze xs width height) [(w,h-1)] stop [(w,h)] 0)
                              else (solvePerfect1 (Maze xs width height) [(w,h)] stop previous (flag+1))


findN :: (Int,Int) ->  Int -> Int
findN (a,b) w = (b-1)*w + a


--solve braid                                                                           
solveBraid :: Maze -> (Int, Int) -> (Int, Int) -> [(Int, Int)]
solveBraid maze (a,b) (c,d) = dfs2 maze [] [(a+1,b+1)] [(c+1,d+1)] [(-1,-1)] 0


dfs2 :: Maze -> [(Int, Int)] -> [(Int, Int)] -> [(Int, Int)] ->  [(Int, Int)] -> Int -> [(Int,Int)]
dfs2 (Maze xs width height) ys [(w,h)] stop previous flag =
                          if [(w,h)] == stop then stop
                                  else
                                      do
                                     -- down
                 if (((dWall xs (findY xs (findN (w,h) width)) (findN (w,h) width) width height)== 0) Prelude.&& (previous /= [(w,h+1)] Prelude.&& mod flag 4==0) Prelude.&& (checkGoal2 (Maze xs width height) ((w,h):ys) [(w,h+1)] stop [(w,h)])==True Prelude.&& elem (w,h+1) ys ==False)
                   then ((w,h):dfs2 (Maze xs width height) ((w,h):ys) ([(w,h+1)]) stop [(w,h)] 0)
                   else 
                                        -- right
                     if (((rWall xs (findY xs (findN (w,h) width)) (findN (w,h) width) width height)== 0) Prelude.&& (previous /= [(w+1,h)] Prelude.&& mod flag 4==1) Prelude.&& (checkGoal2 (Maze xs width height) ((w,h):ys) [(w+1,h)] stop [(w,h)])==True Prelude.&& elem (w+1,h) ys ==False)
                       then ((w,h):dfs2 (Maze xs width height) ((w,h):ys) [(w+1,h)] stop [(w,h)] 0)
                       else 
                                        -- left
                        if (((lWall xs (findY xs (findN (w,h) width)) (findN (w,h) width) width height)== 0) Prelude.&& (previous /= [(w-1,h)] Prelude.&& mod flag 4==2) Prelude.&& (checkGoal2 (Maze xs width height) ((w,h):ys) [(w-1,h)] stop [(w,h)])==True Prelude.&& elem (w-1,h) ys ==False)
                          then ((w,h):dfs2 (Maze xs width height) ((w,h):ys) [(w-1,h)] stop [(w,h)] 0)
                          else 
                                        -- up
                            if (((uWall xs (findY xs (findN (w,h) width)) (findN (w,h) width) width height)== 0) Prelude.&& (previous /= [(w,h-1)] Prelude.&& mod flag 4==3) Prelude.&& (checkGoal2 (Maze xs width height) ((w,h):ys) [(w,h-1)] stop [(w,h)])==True Prelude.&& elem (w,h-1) ys ==False)
                              then ((w,h):dfs2 (Maze xs width height) ((w,h):ys) [(w,h-1)] stop [(w,h)] 0)
                              else (dfs2 (Maze xs width height) (ys) [(w,h)] stop previous (flag+1))


checkGoal2 :: Maze -> [(Int, Int)] -> [(Int, Int)] -> [(Int, Int)] ->  [(Int, Int)] -> Bool
checkGoal2 (Maze xs width height) ys [(w,h)] stop previous = if [(w,h)] == stop then True
                                                                            else
                 (if (((dWall xs (findY xs (findN (w,h) width)) (findN (w,h) width) width height)== 0) Prelude.&& (elem (w,h+1) ys)==False)
                       then (checkGoal2 (Maze xs width height) ((w,h):ys) ([(w,h+1)]) stop [(w,h)]) 
                       else False) Prelude.||
                 (if (((rWall xs (findY xs (findN (w,h) width)) (findN (w,h) width) width height)== 0) Prelude.&& (elem (w+1,h) ys)==False)
                       then (checkGoal2 (Maze xs width height) ((w,h):ys) [(w+1,h)] stop [(w,h)]) 
                       else False) Prelude.||
                 (if (((lWall xs (findY xs (findN (w,h) width)) (findN (w,h) width) width height)== 0) Prelude.&& (elem (w-1,h) ys)==False)
                       then (checkGoal2 (Maze xs width height) ((w,h):ys) [(w-1,h)] stop [(w,h)])
                       else False) Prelude.||
                 (if (((uWall xs (findY xs (findN (w,h) width)) (findN (w,h) width) width height)== 0) Prelude.&& (elem (w,h-1) ys)==False)
                       then (checkGoal2 (Maze xs width height) ((w,h):ys) [(w,h-1)] stop [(w,h)])
                       else False)


--first arg: 0 for perfect , 1 for braid , else error
showSolvedMaze :: Int -> Int -> Int -> (Int, Int) -> (Int, Int) -> String
showSolvedMaze 0 w h (a,b) (c,d) = if (a<w Prelude.&& c<w Prelude.&& b<h Prelude.&& d<h)
                                    then do
                                        m <- [kruskal ( makeMaze w h )]
                                        showMaze m (solvePerfect m (a,b) (c,d))
                                    else
                                        "wrong indexes!\n"
showSolvedMaze 1 w h (a,b) (c,d) = if (a<w Prelude.&& c<w Prelude.&& b<h Prelude.&& d<h)
                                    then do
                                        m <- [braid ( kruskal ( makeMaze w h ) )]
                                        showMaze m (solveBraid m (a,b) (c,d))
                                    else
                                        "wrong indexes!\n"
showSolvedMaze _ _ _ (_,_) (_,_) = "wrong arguments!\n"


