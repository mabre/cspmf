-----------------------------------------------------------------------------
-- |
-- Module      :  Language.CSPM.TranslateToProlog
-- Copyright   :  (c) Fontaine 2010 - 2011
-- License     :  BSD3
--
-- Maintainer  :  fontaine@cs.uni-duesseldorf.de
-- Stability   :  experimental
-- Portability :  GHC-only
--
-- Translate a CSPM-specification to Prolog.
-- This is the interface used by Prolog
-----------------------------------------------------------------------------

{-# LANGUAGE ScopedTypeVariables #-}
module Language.CSPM.TranslateToProlog
-- (
--   toPrologVersion
--   ,translateToProlog
--   ,translateExpToPrologTerm
--   ,translateDeclToPrologTerm
-- )
where

-- import Language.CSPM.Frontend as Frontend --TODO
import Language.CSPM.AstUtils
import Language.CSPM.Utils
import Language.CSPM.Parser
import Language.CSPM.Rename
import Language.CSPM.LexHelper
import Language.Prolog.PrettyPrint.Direct



import Language.CSPM.SrcLoc as SrcLoc
import Language.CSPM.Token as Token --(lexEMsg,lexEPos,alexLine,alexCol,alexPos)
import Language.CSPM.CompileAstToProlog (cspToProlog,mkSymbolTable,te,td)
-- import Language.CSPM.AstToProlog (toProlog)
import Language.Prolog.PrettyPrint.Direct
-- import Paths_CSPM_ToProlog (version)
version = makeVersion [0,6,1,1]
import Data.Version (Version,showVersion,makeVersion)
import Data.Maybe

-- import Control.Exception
-- import System.Exit
-- import System.IO
import Text.PrettyPrint

--TODO
import Language.CSPM.AST
type FilePath = String
try = id

native getCPUTime java.lang.System.currentTimeMillis :: () -> IO Long

-- | The version of the CSPM-ToProlog library
toPrologVersion :: Version --TODO
toPrologVersion = version

-- | 'translateExpToPrologTerm' translates a string expression
-- to a prolog term in regard to the given CSP-M specification.
translateExpToPrologTerm ::
     Maybe FilePath
  -> String
  -> IO ()
translateExpToPrologTerm file expr = do
  (r :: {-Either SomeException-} String) <- try $ mainWorkSinglePlTerm getExpPlCode file ("x__entrypoint_expression = " ++ expr)
  handleTranslationResult r
 where
    getExpPlCode :: Module a -> Doc
    getExpPlCode = addFullStopToPrologTerm . Term.unTerm . te . {-Frontend.-}getLastBindExpression
-- | 'translateDeclToPrologTerm' translates a string declaration
-- to a prolog term in regard to the given CSP-M specification.
translateDeclToPrologTerm ::
     Maybe FilePath
  -> String
  -> IO ()
translateDeclToPrologTerm file decl = do
  (r :: {-Either SomeException-} String) <- try $ mainWorkSinglePlTerm getDeclPlCode file decl
  handleTranslationResult r
 where
    getDeclPlCode :: Module a -> Doc
    getDeclPlCode = addFullStopToPrologTerm . Term.unTerm . head . td . {-Frontend.-}getLastDeclaration
	
addFullStopToPrologTerm :: Doc -> Doc
addFullStopToPrologTerm plTerm = plTerm <> (text ".")

{-handleTranslationResult :: Either SomeException String -> IO ()
handleTranslationResult r =
  case r of
    Right res -> putStr res >> exitSuccess
    Left err -> do
      hPutStrLn stderr $ show err
      exitFailure-}  
--TODO
handleTranslationResult :: String -> IO ()
handleTranslationResult r = putStr r

mainWorkSinglePlTerm :: (ModuleFromRenaming -> Doc) -> Maybe FilePath -> String -> IO String
mainWorkSinglePlTerm termFun filePath decl = do
  (specSrc,fileName) <- if isJust filePath then readFile (fromJust filePath) >>= \s -> return (s,fromJust filePath) else return ("","no-file-name")
  let src = specSrc ++ "\n--patch entrypoint\n"++decl ++"\n"
  ast <- {-Frontend.-}parseNamedString fileName src
  (astNew, _) <- eitherToExc $ renameModule ast
  let plTerm = termFun astNew
--   output <- evaluate $ show plTerm
--   return output
  return $ show plTerm --TODO

-- | 'translateToProlog' reads a CSPM specification from inFile
-- and writes the Prolog representation to outFile.
-- It handles all lexer and parser errors and catches all exceptions.
translateToProlog ::
     FilePath -- ^ filename input
  -> FilePath -- ^ filename output
  -> IO ()
translateToProlog inFile outFile = do
  res <- {-handle catchAllExceptions
          $ handleLexError lexErrorHandler
             $ handleParseError parseErrorHandler
               $ handleRenameError renameErrorHandler $-} mainWork inFile
  -- putStrLn "Parsing Done!"
  (r :: {-Either SomeException-} ()) <- try $ writeFile outFile res
  putStrLn "Writing File Done!"
--   case r of
--     Right () -> exitSuccess
--     Left err -> do --TODO
--       hPutStrLn stderr "output-file not written"
--       hPutStrLn stderr $ show err
--       exitFailure

{-
main :: IO ()
main = do
  args <- getArgs
  case args of
    [inFile,outFile] -> do
      translateToProlog inFile outFile
      exitSuccess
    _ -> do
      putStrLn "Start with two arguments (input filename and output filename)"
      exitFailure
-}

mainWork :: FilePath -> IO String
mainWork fileName = do
  src <- readFile fileName

  printDebug $ "Reading File " ++ fileName
  startTime <- (return $ length src) >> getCPUTime ()
  tokenList <- lexInclude fileName src >>= eitherToExc
  time_have_tokens <- getCPUTime ()

  ast <- eitherToExc $ parse fileName tokenList
  time_have_ast <- getCPUTime ()

  printDebug $ "Parsing OK"
  printDebug $ "lextime : " ++ showTime (time_have_tokens - startTime)
  printDebug $ "parsetime : " ++ showTime(time_have_ast - time_have_tokens)
  
  time_start_renaming <- getCPUTime ()
  (astNew, renaming) <- eitherToExc $ renameModule ast
  let
      plCode = cspToProlog astNew
      symbolTable = mkSymbolTable $ renaming.identDefinition
      -- moduleFact  = toProlog astNew
  let output = {-output <- evaluate $-} show $ vcat [ 
        mkResult "ok" "" 0 0 0
        -- ,moduleFact -- writing original ast to .pl file
        ,plCode
        ,symbolTable
        ]

  time_have_renaming <- getCPUTime ()
  printDebug $ "renamingtime : " ++ showTime (time_have_renaming - time_start_renaming)
  printDebug $ "total : " ++ showTime(time_have_ast - startTime)
  return output

showTime :: Long -> String
showTime a = show a ++ "ms"

defaultHeader :: Doc
defaultHeader 
  =    text ":- dynamic parserVersionNum/1, parserVersionStr/1, parseResult/5."
    $$ text ":- dynamic module/4."
    $$ simpleFact "parserVersionStr" [aTerm $ showVersion toPrologVersion]

simpleFact :: String -> [Term] -> Doc
simpleFact a l= plPrg [declGroup [clause $ termToClause $ nTerm a l]]

mkResult :: String -> String -> Int -> Int -> Int -> Doc
mkResult var msg line col pos
  = defaultHeader   
    $$ simpleFact "parseResult" [aTerm var, aTerm msg, aTerm line, aTerm col, aTerm pos]

printDebug :: String -> IO ()
-- printDebug _ = return () -- TODO
printDebug = putStrLn

-- TODO
-- parseErrorHandler :: ParseError -> IO String
-- parseErrorHandler err = do
--   printDebug "ParseError : "
--   printDebug $ show err
--   let loc = Frontend.parseErrorPos err
--   evaluate $ show
--     $ mkResult "parseError"
--         (Frontend.parseErrorMsg err)
--         (Token.alexLine loc)
--         (Token.alexCol loc)
--         (Token.alexPos loc)
-- 
-- lexErrorHandler :: LexError -> IO String
-- lexErrorHandler err = do
--   printDebug "LexError : "
--   printDebug $ show err
--   let loc = Token.lexEPos err
--   evaluate $ show
--     $ mkResult "lexError"
--         (Token.lexEMsg err)
--         (Token.alexLine loc)
--         (Token.alexCol loc)
--         (Token.alexPos loc)
-- 
-- renameErrorHandler :: RenameError -> IO String
-- renameErrorHandler err = do 
--   printDebug "RenamingError : "
--   printDebug $ show err
--   let loc = Frontend.renameErrorLoc err
--   evaluate $ show
--     $ mkResult "renameError"
--         (Frontend.renameErrorMsg err)
--         (SrcLoc.getStartLine loc)
--         (SrcLoc.getStartCol loc)
--         (SrcLoc.getStartOffset loc)

-- catchAllExceptions :: SomeException -> IO String
-- catchAllExceptions err = do
--   printDebug "ParserException : "
--   printDebug $ show err
--   evaluate $ show $ mkResult "exception" (show err) 0 0 0
