module UtilsTest

where

import Utils

main :: [String] -> IO String
main args = do ast <- parseFile $ head args
               print $ show ast
               writeFile "out_fr" (show ast)
               return "ok"
