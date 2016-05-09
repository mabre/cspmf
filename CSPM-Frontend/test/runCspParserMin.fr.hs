module RunCspParserMin where

-- #!/usr/bin/env runhaskell
{-
first argument is the name of cspm-file
read file, parse it and write the result to a File
-}

-- import Language.CSPM.Frontend
import Language.CSPM.Rename
import Language.CSPM.Parser
import Language.CSPM.LexHelper
import Language.CSPM.Utils
import Language.CSPM.AstUtils
import Data.Typeable

main args
  = do
  let fileName = head args

  ast <- parseFile fileName

  writeFile (fileName ++ ".ast") $ show ast
  let smallAst = removeSourceLocations $ ast
  writeFile (fileName ++ ".clean.ast") $ show smallAst
  
  let ren = renameModule ast
  
  writeFile (fileName ++ ".rename.ast") $ show ren
