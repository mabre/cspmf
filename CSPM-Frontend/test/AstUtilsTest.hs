module AstUtilsTest where

import Language.CSPM.AST
import Language.CSPM.AstUtils
import Language.CSPM.Utils
import Language.CSPM.Parser
import Data.Data
import Data.Generics.Schemes --(everywhere,listify)
import Data.Generics.Aliases --(mkT)

main :: [String] -> IO ()
main args = do
  ast <- parseFile $ head args
  writeFile "out" (show ast)
  writeFile "out2" (show (removeSourceLocations ast))
