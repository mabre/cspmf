----------------------------------------------------------------------------
-- |
-- Module      :  Language.CSPM.UnicodeSymbols
--
-- Stability   :  experimental
-- Portability :  GHC-only
--
-- Unicode symbols for CPSM operators

module UnicodeSymbols
where

import TokenClasses
import Data.Array (Array)
import Data.Map (Map)

unicodeSymbols :: [(Char, PrimToken, String)]
unicodeSymbols = [
      ('¬'    ,T_not               ,"not"     ) --   ¬ 
--    , ('\964'    ,T_tau               ,"tau"     ) --   τ
--    , ('\8714'   ,T_member            ,"member"  ) --   ∊
    , ('∥'   ,T_parallel          ,"||"      ) --   ∥
    , ('∧'   ,T_and               ,"and"     ) --   ∧
    , ('∨'   ,T_or                ,"or"      ) --   ∨
--    , ('\8745'   ,T_inter             ,"inter"   ) --   ∩
--    , ('\8746'   ,T_union             ,"union"   ) --   ∪
    , ('≠'   ,T_neq               ,"!="      ) --   ≠
    , ('≡'   ,T_eq                ,"=="      ) --   ≡
    , ('≤'   ,T_le                ,"<="      ) --   ≤
    , ('≥'   ,T_ge                ,">="      ) --   ≥
    , ('⊑'   ,T_Refine            ,"[="      ) --   ⊑
    , ('⊓'   ,T_sqcap             ,"|~|"     ) --   ⊓
--    , ('\8898'   ,T_Inter             ,"Inter"   ) --   ⋂
--    , ('\8899'   ,T_Union             ,"Union"   ) --   ⋃
    , ('△'   ,T_triangle          ,"/\\"     ) --   △
    , ('▷'   ,T_rhd               ,"[>"      ) --   ▷
    , ('▸'   ,T_exp               ,"|>"      ) --   ▸
    , ('◻'   ,T_box               ,"[]"      ) --   ◻
    , ('➔'  ,T_rightarrow        ,"->"      ) --   ➔
    , ('⟦'  ,T_openBrackBrack    ,"[["      ) --   ⟦
    , ('⟧'  ,T_closeBrackBrack   ,"]]"      ) --   ⟧
    , ('⟨'  ,T_lt                ,"<"       ) --   ⟨
    , ('⟩'  ,T_gt                ,">"       ) --   ⟩
    , ('⟷'  ,T_leftrightarrow    ,"<->"     ) --   ⟷
    ]

{-
tableLine (char,tok,string) = concat
      [ "    , ("
      , tab 10 $ ("'\\" ++ (show $ fromEnum char) ++ "'"),","
      , tab 20 $ show tok, ","
      , tab 10 $ show string, ") --   "
      , [char], "\n"
      ]
  where
    tab x s = take x $ s ++ repeat ' '
-}


lookupDefaultSymbol :: PrimToken -> (Maybe (Char,String))
lookupDefaultSymbol = (Array.!!) table
  where
    table :: Array.Array PrimToken (Maybe (Char,String))
    table = (Array.//)
              (Array.listArray (minBound,maxBound) $ repeat Nothing)
              [(tok,Just (uni,ascii)) | (uni,tok,ascii) <- unicodeSymbols]

lookupToken :: Char -> Maybe PrimToken
lookupToken = flip (Map.lookup) symbolMap
  where
    symbolMap = Map.fromList [(uni,tok) | (uni,tok,_string) <- unicodeSymbols]