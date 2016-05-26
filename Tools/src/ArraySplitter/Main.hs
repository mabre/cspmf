module ArraySplitter where

import Data.List

-- NOTE This program does not work in Frege, out of heap space with big input. :(

-- | Splits the list of integers args!!1 named n=args!!0 into several arrays n# of
-- maximum length 3000 and returns definitions for those arrays as well as there sum.
-- Eg. main ["name", "1,2,3,...,4000"] returns
-- main0 undefined ++ main1 undefined\nmain0 a = [1,2,3,...,3000]\nmain1 a = [3001,...,4000]
-- n# must be functions with parameter because the maximum size for static variables
-- in Java is reached after translation to Java. (javac error: code too large -
-- A single method in a Java class may be at most 64KB of bytecode.)
main :: [String] -> IO ()
main args = putStrLn $ show $ unlines $ arrsum : fs
    where
        name = args !! 0
        arr  = args !! 1
        elems = map atoi $ ´,´.splitted arr
        (names, fs) = generate elems name 0
        arrsum = concat (intersperse " ++ " (map (++ " undefined") names))

-- | Splits the given list in functions returning a list with max. 3000 elements.
-- The function names are composed from the given string and counter.
-- Return a list of function names and the functions.
generate :: [Int] -> String -> Int -> ([String], [String])
generate [] _    _ = ([], [])
generate xs name c = (fname : fnames, function : functions)
    where (l,ls) = splitAt 3000 xs
          fname  = name ++ show c
          function = fname ++ " a = [" ++ concat (intersperse "," (map show l)) ++ "]"
          (fnames, functions) = generate ls name (c+1)