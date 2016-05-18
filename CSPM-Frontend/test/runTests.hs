module RunTests where

import Language.CSPM.TranslateToProlog
import System.Environment
import System.CPUTime
import System.Process

main = do
    args <- getArgs
    startTime <- getCPUTime
    times <- if length args == 1
       then sequence [fmap show $ doWork $ head args]
       else sequence $ map call args
    endTime <- getCPUTime
    let total = ptom (endTime - startTime)
    putStrLn $ "total: " ++ (show $ total) ++ "ms"
    putStrLn $ "  " ++ (show $ ptom $ total `div` (fromIntegral $ length args)) ++ "ms/file"
    putStrLn "Per-file call times:"
    sequence $ map putStrLn times

call :: String -> IO String
call fileName = readProcess "test/runTests" [fileName] ""

doWork :: String -> IO Integer
doWork fileName = do
    startTime <- getCPUTime
    translateToProlog fileName (fileName ++ ".hs.pl")
    endTime <- getCPUTime
    return $ ptom $ endTime - startTime

ptom :: Integer -> Integer
ptom i = i `div` 1000000