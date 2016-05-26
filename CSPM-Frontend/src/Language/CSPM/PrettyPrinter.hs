----------------------------------------------------------------------------
-- |
-- Module      :  Language.CSPM.PrettyPrinter
-- Copyright   :  (c) Ivaylo Dobrikov 2010,2013
-- License     :  BSD
-- 
-- Maintainer  :  Ivaylo Dobrikov (dobrikov84@yahoo.com)
-- Stability   :  experimental
-- Portability :  GHC-only
-- 
-- This module defines functions for pretty-printing the 
-- Abstract Syntax Tree to CSPM syntax.
-----------------------------------------------------------------------------
{-# OPTIONS_GHC -fno-warn-orphans #-}

module Language.CSPM.PrettyPrinter
-- ( TODO
--   pPrint
-- )
where

import Text.PrettyPrint

import Language.CSPM.AST

instance (Pretty x) => Pretty (Labeled x) where
  pPrint = pPrint . Labeled.unLabel

instance Pretty (Module a) where
  pPrint m = vcat $ map pPrint m.moduleDecls


-- help functions for the Instances of the Type-class Pretty
private dot :: Doc
private dot = text "."

private pPrintListSet :: (Pretty r) => String -> String -> r -> Maybe [LCompGen] -> Doc
private pPrintListSet str1 str2 range mgen  =
     case mgen of
       Nothing  -> text str1 <+>  pPrint range <+>  text str2
       Just gen -> text str1 <+> pPrint range <+> text "|"
                    <+> (hsep $ punctuate comma (map (pPrintCompGen False) gen)) <+> text str2

private hsepPrintunctuate :: (Pretty t) => Doc -> [t] -> Doc
private hsepPrintunctuate s l = hsep $ punctuate s $ map pPrint l

private hcatPunctuate :: (Pretty t) => Doc -> [t] -> Doc
private hcatPunctuate s l = hcat $ punctuate s $ map pPrint l

private printFunBind :: LIdent -> [FunCase] -> Doc
private printFunBind ident lcase = vcat $ map (printIdent (ident.unLabel) <>) (map printCase lcase) 

private printCase :: FunCase -> Doc
private printCase c = case c of
    FunCaseI pat  expr -> (parens $ hcatPunctuate comma pat) <+> equals <+> pPrint expr
    FunCase  list expr -> (hcat $ map mkPat list) <+> equals <+> pPrint expr
  where
    mkPat l = parens $ hcatPunctuate comma l

instance Pretty Decl where
  pPrint d = case d of
    PatBind pat expr -> pPrint pat  <+> equals <+> (pPrint expr)
    FunBind ident lcase -> printFunBind ident lcase
    Assert a -> text "assert" <+> pPrint a
    Transparent ids
      -> text "transparent" <+> (hsep $ punctuate comma (map (printIdent . Labeled.unLabel) ids))
    SubType ident constrs
      ->     text "subtype" <+> printIdent (ident.unLabel) <+> equals
         <+> (vcat $ punctuate (text " |") (map printConstr (map Labeled.unLabel constrs)))
    DataType ident constrs
      ->     text "datatype" <+> printIdent (ident.unLabel) <+> equals 
         <+> (hsep $ punctuate (text " |") (map printConstr (map Labeled.unLabel constrs)))
    NameType ident typ
      -> text "nametype" <+> printIdent (ident.unLabel) <+> equals <+> typeDef typ
    Channel ids t
      -> text "channel" <+> (hsep $ punctuate comma $ map (printIdent . Labeled.unLabel) ids) <+> typ
       where
         typ = case t of
           Nothing -> empty
           Just x -> text ":" <+> typeDef x
    Print expr -> text "print"  <+> pPrint expr

private printFunArgs :: [[LExp]] -> Doc
private printFunArgs = hcat . map (parens . hsepPrintunctuate comma)

-- Contructors
private printConstr :: Constructor -> Doc
private printConstr (Constructor ident typ) = printIdent (ident.unLabel) <>
  case typ of 
   Nothing -> empty
   Just t  -> dot <> typeDef t

-- Type Definitions
{-
typeDef :: LTypeDef -> Doc
typeDef typ = case unLabel typ of
  TypeTuple e -> parens $ hcatPunctuate comma e
  TypeDot e -> hcatPunctuate dot e
-}

private typeDef :: LTypeDef -> Doc
private typeDef typ = case typ.unLabel of
  TypeDot na_tuples -> typeDotArgs na_tuples

private typeDotArgs :: [LNATuples] -> Doc
private typeDotArgs na_tuples = hcat $ punctuate dot (map typeNATuples na_tuples)
  where
    typeNATuples :: LNATuples -> Doc
    typeNATuples na_tuple = case na_tuple.unLabel of
       SingleValue e -> pPrint e
       TypeTuple le  -> parens $ hcatPunctuate comma le

instance Pretty Exp where
  pPrint expression = case expression of
    Var ident -> printIdent $ ident.unLabel
    IntExp i -> integer i
    SetExp range mgen -> pPrintListSet "{"  "}" range mgen
    ListExp range mgen -> pPrintListSet "<"  ">" range mgen
    ClosureComprehension (lexp,lcomp)
      -> pPrintListSet "{|" "|}" (labeled $ RangeEnum lexp) (Just lcomp)
    Let ldecl expr -> vcat
      [
       nest 2 (text "let")
      ,vcat $ punctuate (text "" $$ nest 4 (text "")) (map pPrint ldecl)
      ,nest 2 (text "within" <+> pPrint expr)
      ]
    Ifte expr1 expr2 expr3 -> vcat
      [
       nest 2 $ text "if" <+> pPrint expr1
      ,nest 4 $ text "then" <+> pPrint expr2
      ,nest 4 $ text "else" <+> pPrint expr3
      ]
    CallFunction expr list -> pPrint expr  <> printFunArgs list
    CallBuiltIn  builtin [expr] -> pPrint builtin <> (parens $ hsepPrintunctuate comma expr)
    CallBuiltIn  _ _ -> error "pPrint Exp: builtin must have exactly one argument"
    Lambda pat expr -> text "\\" <+> hsepPrintunctuate comma pat <+> text "@" <+> pPrint expr
    Stop    -> text "STOP"
    Skip    -> text "SKIP"
    CTrue   -> text "true"
    CFalse  -> text "false"
    Events  -> text "Events"
    BoolSet -> text "Bool"
    IntSet  -> text "Int"
    TupleExp e      -> parens $ hsepPrintunctuate comma e
    Parens e        -> parens $ pPrint e
    AndExp a b      -> pPrint a <+> text "and" <+> pPrint b
    OrExp a b       -> pPrint a<+> text "or" <+> pPrint b
    NotExp e        -> text "not" <+> pPrint e
    NegExp e        -> text " " <> text "-" <>  pPrint e
    Fun1 builtin e  -> pPrint builtin <> (parens $ pPrint e)
    Fun2 builtin a b -> pPrint a <+> pPrint builtin <+> pPrint b
    DotTuple l      -> hcatPunctuate dot l
    Closure e       -> text "{|" <+> hsepPrintunctuate comma e <+> text "|}"

-- process expressions
    ProcSharing e p1 p2 -> pPrint p1 <> text "[|" <+> pPrint e <+> text "|]" <> pPrint p2
    ProcAParallel expr1 expr2  p1 p2
      -> pPrint p1 <> (brackets $ pPrint expr1 <+> text "||" <+> pPrint expr2) <> pPrint p2
    ProcLinkParallel llist p1 p2 -> pPrint p1 <> pPrint llist <> pPrint p2
    ProcRenaming renames mgen proc
      -> pPrint proc  <> text "[[" <+> hsepPrintunctuate comma renames <+> gens <+> text "]]"
         where
           gens = case mgen of
                    Nothing   -> empty
                    Just lgen -> text "|" <+> (separateGen False (lgen.unLabel))
                                                                          
    ProcException e p1 p2 -> pPrint p1 <+> text "[|" <+> pPrint e <+> text "|>" <+> pPrint p2
    ProcRepSequence lgen proc -> replicatedProc (text ";")   (lgen.unLabel) proc
    ProcRepInternalChoice lgen proc -> replicatedProc (text "|~|") (lgen.unLabel) proc
    ProcRepExternalChoice lgen proc -> replicatedProc (text "[]")  (lgen.unLabel) proc
    ProcRepInterleave lgen proc -> replicatedProc (text "|||") (lgen.unLabel) proc
    PrefixExp expr fields proc
        -> pPrint expr <> (hcat $ map pPrint fields) <+> text "->" <+> pPrint proc
    ProcRepSharing lgen expr proc
        ->     text "[|" <+> pPrint expr <+> text "|]"
           <+> (separateGen True (lgen.unLabel)) <+> text "@" <+> pPrint proc
    ProcRepAParallel lgen expr proc
        -> text "||" <+> (separateGen True (lgen.unLabel)) <+> text "@" 
                                                  <+> (brackets $ pPrint expr) <+> pPrint proc
    ProcRepLinkParallel lgen llist proc
        -> pPrint llist  <+> (separateGen True (lgen.unLabel)) <+> text "@" <+> pPrint proc

-- only used in later stages
-- this do not affect the CSPM notation: same outputs as above
    PrefixI _ expr fields proc -> pPrint expr <> (hcat $ map pPrint fields) <+> text "->" <+> pPrint proc
    LetI decls _ expr -> hcat
       [
        nest 2 $ text "let"
       ,nest 4 $ hcat $ map pPrint decls
       ,nest 2 $ text "within" <+> pPrint expr
       ]
    LambdaI _ pat expr
        -> text "\\" <+> hsepPrintunctuate comma pat <+> text "@" <+> pPrint expr
    ExprWithFreeNames _ expr -> pPrint expr

private replicatedProc :: Doc -> [LCompGen] -> LProc -> Doc
private replicatedProc op lgen proc = op <+> (separateGen True lgen) <+> text "@" <+> pPrint proc

instance Pretty LinkList where
  pPrint (LinkList list)                   = brackets $ hsepPrintunctuate comma list
  pPrint (LinkListComprehension lgen list)
    = brackets (hsepPrintunctuate comma list <+> text "|" <+> separateGen False lgen)

instance Pretty Link where
  pPrint (Link expr1 expr2) = pPrint expr1 <+> text "<->" <+> pPrint expr2

instance Pretty Rename where
  pPrint (Rename expr1 expr2) = pPrint expr1 <+> text "<-" <+> pPrint expr2

private separateGen :: Bool -> [LCompGen] -> Doc
private separateGen b lgen = hsep $ punctuate comma $ map (pPrintCompGen b) lgen

-- the generators of the comprehension sets, lists (all after the |) and 
-- inside replicated processes (like "x: {1..10}", in this case the bool variable must be true,
-- otherwise false)
private pPrintCompGen :: Bool -> LCompGen -> Doc
private pPrintCompGen b gen = case gen.unLabel of
  (Generator pat expr) -> (pPrint pat) <+> case b of
           False -> text "<-" <+> (pPrint expr)
           True  -> text ":"  <+> (pPrint expr)
  (Guard expr)         -> pPrint expr

-- the range of sets and lists
instance Pretty Range where
  pPrint r = case r of
    RangeEnum expr -> hsepPrintunctuate comma expr
    RangeClosed a b -> pPrint a <> text ".." <> pPrint b
    RangeOpen expr -> pPrint expr <> text ".."

-- unwrapPrint the BuiltIn-oparator
instance Pretty BuiltIn where
  pPrint (BuiltIn c) = pPrint c

-- the communication fields
instance Pretty CommField where
  pPrint (InComm pat)            = text "?" <> pPrint pat
  pPrint (InCommGuarded pat expr) = text "?" <> pPrint pat <> text ":" <> pPrint expr
  pPrint (OutComm expr)           = text "!" <> pPrint expr

-- pretty-printing for CSPM-Patterns
instance Pretty Pattern where
  pPrint pattern = case pattern of
    IntPat n         -> integer n
    TruePat          -> text "true"
    FalsePat         -> text "false"
    WildCard         -> text "_"
    ConstrPat ident  -> printIdent $ ident.unLabel
    Also pat         -> pPrintAlso (Also pat)
    Append pat       -> hcatPunctuate (text "^") pat
    DotPat []        -> error "pPrint Pattern: empty dot pattern"
    DotPat [pat]     -> pPrint pat
    DotPat l         -> hcat $ punctuate dot $ map nestedDotPat l
    SingleSetPat pat -> text "{" <+> (pPrint pat) <+> text "}"
    EmptySetPat      -> text "{ }"
    ListEnumPat pat  -> text "<" <+> hsepPrintunctuate comma pat <+> text ">"
    TuplePat pat     -> text "(" <> hsepPrintunctuate comma pat <>  text ")"
    VarPat ident     -> printIdent $ ident.unLabel
    Selectors _ _    -> error "pPrint Pattern Seclectors"
    Selector _ _     -> error "pPrint Pattern Seclector"
   where
      nestedDotPat p = case p.unLabel of
        DotPat {} -> parens $ pPrint p
        x -> pPrint x

-- external function for Also-Patterns for a better look
private pPrintAlso :: Pattern -> Doc
private pPrintAlso (Also [])    = text ""
private pPrintAlso (Also (h:t)) =
   case h.unLabel of
     DotPat _ -> if length t > 0 then (pPrint h) <> text "@@" <> pPrintAlso (Also t)
                                 else pPrint h
     Append _ -> if length t > 0 then (pPrint h) <> text "@@" <> pPrintAlso (Also t)
                                 else pPrint h
     _        -> if length t > 0 then pPrint h <> text "@@" <> pPrintAlso (Also t)
                                 else pPrint h
private pPrintAlso _ = text ""

-- disticts the cases for different syntax-records for the Ident datatype
private printIdent :: Ident -> Doc
private printIdent ident = 
  case ident of 
   Ident _  -> text $ ident.unIdent
   UIdent _ -> text $ (unUIdent ident).newName

instance Pretty AssertDecl where
  pPrint a = case a of
     AssertBool expr -> pPrint expr
     AssertRefine n expr1 op expr2
       -> negated n $ pPrint expr1 <+> pPrint op <+> pPrint expr2
     AssertLTLCTL n expr t str
       -> negated n $ pPrint expr <+> text "|=" <+> pPrint t <+> text "\"" <> text str <> text "\""
     AssertTauPrio n expr1 op expr2 expr3
       -> negated n $ pPrint expr1 <+> pPrint op <+> pPrint expr2 <+> text ":[tau priority over]:" <+> pPrint expr3
     AssertModelCheck n expr m mb
       -> negated n $ pPrint expr <+> text ":[" <+> pPrint m <+> maybe empty pPrint mb <+> text "]"
    where
      negated ar doc = if ar then text "not" <+> doc else doc

instance Pretty FdrExt where
  pPrint i = case i of
    F  -> text "[F]"
    FD -> text "[FD]"
    T  -> text "[T]"

instance Pretty FDRModels where
  pPrint m = case m of
    DeadlockFree  -> text "deadlock free"
    Deterministic -> text "deterministic"
    LivelockFree  -> text "livelock free"

instance Pretty RefineOp where
  pPrint x = case x of
    Trace -> text "[T="
    Failure -> text "[F="
    FailureDivergence -> text "[FD="
    RefusalTesting -> text "[R="
    RefusalTestingDiv -> text "[RD="
    RevivalTesting -> text "[V="
    RevivalTestingDiv -> text "[VD="
    TauPriorityOp -> text "[TP="

instance Pretty TauRefineOp where
  pPrint TauTrace = text "[T="
  pPrint TauRefine = text "[="

instance Pretty FormulaType where
  pPrint LTL = text "LTL:"
  pPrint CTL = text "CTL:"

instance Pretty Const where
  pPrint x = case x of
-- Booleans
    F_true   -> text "true"
    F_false  -> text "false"
    F_not    -> text "not"
    F_and    -> text "and"
    F_or     -> text "or"
-- Numbers
    F_Mult   -> text "*"
    F_Div    -> text "/"
    F_Mod    -> text "%"
    F_Add    -> text "+"
    F_Sub    -> text "" <+> text "-"
-- Equality
    F_GE     -> text ">="
    F_LE     -> text "<="
    F_LT     -> text "<"
    F_GT     -> text ">"
    F_Eq     -> text "=="
    F_NEq    -> text "!="
-- Sets
    -- F_union  -> text "union"
    -- F_inter  -> text "inter"
    -- F_diff   -> text "diff"
    -- F_Union  -> text "Union"
    -- F_Inter  -> text "Inter"
    -- F_member -> text "member"
    -- F_card   -> text "card"
    -- F_empty  -> text "empty"
    -- F_set    -> text "set"
    -- F_seq    -> text "seq"
    -- F_Set    -> text "Set"
    -- F_Seq    -> text "Seq"
-- Types
    F_Int    -> text "Int"
    F_Bool   -> text "Bool"
--Sequences
    -- F_null   -> text "null"
    -- F_head   -> text "head"
    -- F_tail   -> text "tail"
    -- F_concat -> text "concat"
    -- F_elem   -> text "elem"
    -- F_length -> text "length"
    F_Concat -> text "^"
    F_Len2   -> text "#"
--process oprators
    F_STOP   -> text "STOP"
    F_SKIP   -> text "SKIP"
    F_Events -> text "Events"
    F_CHAOS  -> text "CHAOS"
    F_Guard  -> text "&"
    F_Sequential -> text ";"
    F_Interrupt  -> text "/\\"
    F_ExtChoice  -> text "[]"
    F_IntChoice  -> text "|~|"
    F_Hiding     -> text "\\"
    F_Timeout    -> text "[>"
    F_Interleave -> text "|||"
