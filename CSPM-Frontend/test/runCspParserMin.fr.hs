module RunCspParserMin where

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

native getCPUTime java.lang.System.currentTimeMillis :: () -> IO Long

main args
  = do
  let fileName = head args

  
doWork :: String -> IO (Long, Long, Long)
doWork filename = do
  t1 <- getCPUTime
  tokenList <- fromRight $ lexInclude filename
  t2 <- getCPUTime
  
  t3 <- getCPUTime
  ast <- fromRight $ parse filename tokenList
  t4 <- getCPUTime
  writeFile (fileName ++ ".fr.ast") $ show ast
  
  t5 <- getCPUTime
  let smallAst = removeSourceLocations $ renameModuleTokens $ ast
  t6 <- getCPUTime
  writeFile (fileName ++ ".fr.clean.ast") $ show smallAst
  
  t7 <- getCPUTime
  astNew <- fromRight $ renameModule ast
  t8 <- getCPUTime
  writeFile (fileName ++ ".fr.rename.newast") $ show astNew
  
  let smallAst = removeSourceLocations $ unUniqueIdent $ removeModuleTokens $ astNew
  writeFile (fileName ++ ".fr.clean.newast") $ showAst smallAst
  
  let ren = renameModule ast
  
  writeFile (fileName ++ ".fr.rename.ast") $ show ren
