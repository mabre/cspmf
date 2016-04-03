module LexerAlexTest where

import Lexer
import Data.List

main :: [String] -> IO ()
main args = do output $ head args

-- main :: [String] -> IO ()
-- main as = do let path = head as
--              files <- ls path
-- --              output $ path ++ "/" ++ (files !! 0)
-- --              output $ path ++ "/" ++ (files !! 1)
-- --              output $ path ++ "/" ++ (files !! 2)
-- --              output $ path ++ "/" ++ (files !! 3)
--              output $ path ++ "/" ++ (files !! 4) -- crossing
-- --              output $ path ++ "/" ++ (files !! 5)
-- --              output $ path ++ "/" ++ (files !! 6)
-- --              output $ path ++ "/" ++ (files !! 7)
-- --              output $ path ++ "/" ++ (files !! 8)
-- --              output $ path ++ "/" ++ (files !! 9)
-- --              output $ path ++ "/" ++ (files !! 10)
-- --              output $ path ++ "/" ++ (files !! 11)
-- --              output $ path ++ "/" ++ (files !! 12)
-- --              output $ path ++ "/" ++ (files !! 13)
-- --              output $ path ++ "/" ++ (files !! 14)
-- --              output $ path ++ "/" ++ (files !! 15)
-- --              output $ path ++ "/" ++ (files !! 16)
-- --              output $ path ++ "/" ++ (files !! 17)
-- --              output $ path ++ "/" ++ (files !! 18)
-- --              output $ path ++ "/" ++ (files !! 19)
-- --              output $ path ++ "/" ++ (files !! 20)
-- --              output $ path ++ "/" ++ (files !! 21)
-- --              output $ path ++ "/" ++ (files !! 22)
-- --              output $ path ++ "/" ++ (files !! 23)
-- --              output $ path ++ "/" ++ (files !! 24)
-- --              output $ path ++ "/" ++ (files !! 25)
-- --              output $ path ++ "/" ++ (files !! 26)
-- --              output $ path ++ "/" ++ (files !! 27)
-- --              output $ path ++ "/" ++ (files !! 28)
-- --              output $ path ++ "/" ++ (files !! 29)
-- --              output $ path ++ "/" ++ (files !! 30)
-- --              output $ path ++ "/" ++ (files !! 31)
-- --              output $ path ++ "/" ++ (files !! 32)
-- --              output $ path ++ "/" ++ (files !! 33)
-- --              output $ path ++ "/" ++ (files !! 34)
-- --              output $ path ++ "/" ++ (files !! 35)
-- --              output $ path ++ "/" ++ (files !! 36)
-- --              output $ path ++ "/" ++ (files !! 37)
-- --              output $ path ++ "/" ++ (files !! 38)
-- --              output $ path ++ "/" ++ (files !! 39)
-- --              output $ path ++ "/" ++ (files !! 40)
-- --              output $ path ++ "/" ++ (files !! 41)
-- --              output $ path ++ "/" ++ (files !! 42)
-- --              output $ path ++ "/" ++ (files !! 43)
-- --              output $ path ++ "/" ++ (files !! 44)
-- --              output $ path ++ "/" ++ (files !! 45)
-- --              output $ path ++ "/" ++ (files !! 46)
-- --              output $ path ++ "/" ++ (files !! 47)
-- --              output $ path ++ "/" ++ (files !! 48)
-- --              output $ path ++ "/" ++ (files !! 49)
-- --              output $ path ++ "/" ++ (files !! 50)
-- --              output $ path ++ "/" ++ (files !! 51)
-- --              output $ path ++ "/" ++ (files !! 52)
-- --              output $ path ++ "/" ++ (files !! 53)
-- --              output $ path ++ "/" ++ (files !! 54)
-- --              output $ path ++ "/" ++ (files !! 55)
--              return ()

-- http://stackoverflow.com/questions/35710138/could-not-import-module-frege-system-directory-java-lang-classnotfoundexception
ls :: String -> IO [String]
ls dir = do
   contents <- File.new dir >>= _.list
   maybe (return []) (JArray.fold (flip (:)) []) contents

tokenize :: String -> IO String
tokenize f = do contents <- readFile f
                return $ show $ scanner contents

output :: String -> IO ()
output f = do putStrLn f
              contents <- tokenize f
              putStrLn contents
              return ()
