module LexerAlexTest where

import Language.CSPM.Lexer
import frege.data.List

main :: [String] -> IO ()
main args = do output $ head args

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
