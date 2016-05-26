-----------------------------------------------------------------------------
-- |
-- Module      :  Language.CSPM.Utils
-- Copyright   :  (c) Fontaine 2008
-- License     :  BSD
-- 
-- Maintainer  :  fontaine@cs.uni-duesseldorf.de
-- Stability   :  experimental
-- Portability :  GHC-only
--
-- Some Utilities

module Language.CSPM.Utils
--  (eitherToExc
--  ,handleLexError
--  ,handleParseError
--  ,handleRenameError
--  ,parseFile, benchmarkFrontend, parseString, parseNamedString)
where

-- import Debug.Trace -- TODO

import Language.CSPM.Token (Token, LexError, LexErrorException)
import Language.CSPM.Parser (ParseError, ParseErrorException, parse)
import Language.CSPM.Rename (RenameError, RenameErrorException, renameModule, ModuleFromRenaming)
import Language.CSPM.Token (LexError)
import Language.CSPM.AST (ModuleFromParser)
-- import Language.CSPM.PrettyPrinter(pPrint) -- TODO
import Language.CSPM.LexHelper as Lexer (lexInclude,lexPlain)

type FilePath = String

-- import Control.Exception as Exception
-- import System.CPUTime

-- catchLexError :: IO a               -- ^ The computation to run
--              -> (LexError -> IO a)  -- ^ Handler to invoke if an exception is raised
--              -> IO a
-- catchLexError io handler = do
--     res <- io
--     case io of
--          (err@(LexError _ _)) -> handler err
--          noerr                -> return noerr
--     
--     
--     IO $ catch# io handler'
--     where handler' e = case fromException e of
--                        Just e' -> unIO (handler e')
--                        Nothing -> raiseIO# e

-- | "eitherToExc" returns the Right part of "Either" or throws the Left part as an dynamic exception. "throw" is a function like throwIO . NativeJavaException.new.
eitherToExc :: (a -> IO b) -> Either a b ->  IO b
eitherToExc _     (Right r) = return r
eitherToExc throw (Left e)  = throw e

throwLexError :: LexError -> IO a
throwLexError = (throwIO . LexErrorException.new)

throwParseError :: ParseError -> IO a
throwParseError = (throwIO . ParseErrorException.new)

throwRenameError :: RenameError -> IO a
throwRenameError = (throwIO . RenameErrorException.new)

-- | Lex and parse a file and return a "LModule", throw an exception in case of an error
parseFile :: FilePath -> IO ModuleFromParser
parseFile fileName = do
  src <- readFile fileName
  parseNamedString fileName src

-- | Small test function which just parses a String.
parseString :: String -> IO ModuleFromParser
parseString = parseNamedString "no-file-name"

parseNamedString :: FilePath -> String -> IO ModuleFromParser
parseNamedString name str = do
  tokenList <- Lexer.lexInclude name str >>= eitherToExc throwLexError
  eitherToExc throwParseError $ parse name tokenList

-- | Test function that parses a string and then pretty prints the produced AST
-- parseAndPrettyPrint :: String -> IO String -- TODO
-- parseAndPrettyPrint str = do
--   ast <- parseString str
--   return $ show $ pPrint ast

-- | Lex and parse File.
-- | Return the module and print some timing infos
-- benchmarkFrontend :: FilePath -> IO (ModuleFromParser, ModuleFromRenaming)
benchmarkFrontend fileName = undefined -- do TODO
--   src <- readFile fileName
-- 
--   putStrLn $ "Reading File " ++ fileName
--   startTime <- (return $ length src) >> getCPUTime
--   tokenList <- Lexer.lexInclude fileName src >>= eitherToExc
--   time_have_tokens <- getCPUTime
-- 
--   ast <- eitherToExc $ parse fileName tokenList
--   time_have_ast <- getCPUTime
-- 
--   (astNew, _renaming) <- eitherToExc $ renameModule ast
--   time_have_renaming <- getCPUTime
-- 
--   putStrLn $ "Parsing OK"
--   putStrLn $ "lextime : " ++ showTime (time_have_tokens - startTime)
--   putStrLn $ "parsetime : " ++ showTime(time_have_ast - time_have_tokens)
--   putStrLn $ "renamingtime : " ++ showTime (time_have_renaming - time_have_ast)
--   putStrLn $ "total : " ++ showTime(time_have_ast - startTime)
--   return (ast,astNew)
--  where
--     showTime :: Integer -> String
--     showTime a = show (div a 1000000000) ++ "ms"
