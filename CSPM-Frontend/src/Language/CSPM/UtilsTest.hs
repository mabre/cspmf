module UtilsTest

where

import Utils

main :: IO String
main = --fmap show $ parseFile "/home/markus/Downloads/frege/cspmf/CSPM-Frontend/test/cspm/very_simple.csp"
--             putStrLn "ok"
   do a <- parseString "datatype FRUIT = a"
      putStrLn $ "> " ++ show a
      return "ok"

