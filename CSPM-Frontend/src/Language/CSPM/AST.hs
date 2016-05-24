----------------------------------------------------------------------------
-- |
-- Module      :  Language.CSPM.AST
-- Copyright   :  (c) Fontaine 2008 - 2012
-- License     :  BSD3
-- 
-- Maintainer  :  Fontaine@cs.uni-duesseldorf.de
-- Stability   :  experimental
-- Portability :  GHC-only
--
-- This module defines an Abstract Syntax Tree for CSPM.
-- This is the AST that is computed by the parser.
-- For historical reasons, it is rather unstructured.

module Language.CSPM.AST
where

import Language.CSPM.Token
import Language.CSPM.SrcLoc

import Data.Data
-- import Data.IntMap (IntMap) -- TODO IntMap efficiency
import Data.Map (Map)
import Data.Array
import frege.data.IntMap

type AstAnnotation x = IntMap x
type Bindings = Map String UniqueIdent
type FreeNames = IntMap UniqueIdent

{-# derive DataTypeable #-}
data NodeId = NodeId {unNodeId :: Int}
derive Eq NodeId
derive Ord NodeId
derive Show NodeId
succ' :: NodeId -> NodeId
succ' (NodeId i) = NodeId $ succ i

mkNodeId :: Int -> NodeId
mkNodeId = NodeId

{-# derive DataTypeable #-}
data Labeled t = Labeled {
    nodeId :: NodeId
   ,srcLoc  :: SrcLoc
   ,unLabel :: t
}
derive Eq (Labeled t)
derive Ord (Labeled t)
derive Show (Labeled t)

-- | Wrap a node with a dummyLabel.
-- todo: Redo we need a specal case in DataConstructor Labeled.
labeled :: t -> Labeled t
labeled t = Labeled {
 nodeId  = NodeId (-1)
 ,unLabel = t
 ,srcLoc  = NoLocation
 }

setNode :: Labeled t -> y -> Labeled y
setNode l n = l.{unLabel = n}

type LIdent = Labeled Ident

{-# derive DataTypeable #-}
data Ident
  = Ident  {unIdent :: String}
  | UIdent UniqueIdent
derive Eq Ident
derive Ord Ident
derive Show Ident


unUIdent :: Ident -> UniqueIdent
unUIdent (UIdent u) = u
unUIdent other = error
  $ "Identifier is not of variant UIdent (missing Renaming) " ++ show other

identId :: LIdent -> Int
identId = UniqueIdent.uniqueIdentId . unUIdent . Labeled.unLabel

{-# derive DataTypeable #-}
data UniqueIdent = UniqueIdent
  {
   uniqueIdentId :: Int
  ,bindingSide :: NodeId
  ,bindingLoc  :: SrcLoc
  ,idType      :: IDType
  ,realName    :: String
  ,newName     :: String
  ,prologMode  :: PrologMode
  ,bindType    :: BindType
}
derive Eq UniqueIdent
derive Ord UniqueIdent
derive Show UniqueIdent

{-# derive DataTypeable #-}
data IDType 
  = VarID | ChannelID | NameTypeID | FunID
  | ConstrID | DataTypeID | TransparentID
  | BuiltInID
derive Eq IDType
derive Ord IDType
derive Show IDType

{-# derive DataTypeable #-}
data PrologMode = PrologGround | PrologVariable
derive Eq PrologMode
derive Ord PrologMode
derive Show PrologMode

{- Actually BindType and PrologMode are semantically aquivalent -}
{-# derive DataTypeable #-}
data BindType = LetBound | NotLetBound
derive Eq BindType
derive Ord BindType
derive Show BindType

isLetBound :: BindType -> Bool
isLetBound x = x==LetBound

{-# derive DataTypeable #-}
data Module a = Module {
   moduleDecls :: [LDecl]
  ,moduleTokens :: Maybe [Token]
  ,moduleSrcLoc :: SrcLoc
  ,moduleComments :: [LocComment]
  ,modulePragmas :: [Pragma]
}
derive Eq (Module a)
derive Ord (Module a)
derive Show (Module a)

{-# derive DataTypeable #-}
data FromParser = FromParser
derive Eq FromParser
derive Show FromParser

castModule :: Module a -> Module b
castModule (Module mds mts msrcloc mcs mps) = Module mds mts msrcloc mcs mps

type ModuleFromParser = Module FromParser

type LExp = Labeled Exp
type LProc = LExp --LProc is just a typealias for better readablility

{-# derive DataTypeable #-}
data Exp
  = Var LIdent
  | IntExp Integer
  | SetExp LRange (Maybe [LCompGen])
  | ListExp LRange (Maybe [LCompGen])
  | ClosureComprehension ([LExp],[LCompGen])
  | Let [LDecl] LExp
  | Ifte LExp LExp LExp
  | CallFunction LExp [[LExp]]
  | CallBuiltIn LBuiltIn [[LExp]]
  | Lambda [LPattern] LExp
  | Stop
  | Skip
  | CTrue
  | CFalse
  | Events
  | BoolSet
  | IntSet
  | TupleExp [LExp]
  | Parens LExp
  | AndExp LExp LExp
  | OrExp LExp LExp
  | NotExp LExp
  | NegExp LExp
  | Fun1 LBuiltIn LExp
  | Fun2 LBuiltIn LExp LExp
  | DotTuple [LExp]
  | Closure [LExp]
  | ProcSharing LExp LProc LProc
  | ProcAParallel LExp LExp LProc LProc
  | ProcLinkParallel LLinkList LProc LProc
  | ProcRenaming [LRename] (Maybe LCompGenList) LProc
  | ProcException LExp LProc LProc
  | ProcRepSequence LCompGenList LProc
  | ProcRepInternalChoice LCompGenList LProc
  | ProcRepExternalChoice LCompGenList LProc
  | ProcRepInterleave LCompGenList LProc
  | ProcRepAParallel LCompGenList LExp LProc
  | ProcRepLinkParallel LCompGenList LLinkList LProc
  | ProcRepSharing LCompGenList LExp LProc--
  | PrefixExp LExp [LCommField] LProc--
-- Only used in later stages.
  | PrefixI FreeNames LExp [LCommField] LProc
  | LetI [LDecl] FreeNames LExp -- freenames of all localBound names
  | LambdaI FreeNames [LPattern] LExp
  | ExprWithFreeNames FreeNames LExp
derive Eq Exp
derive Ord Exp
derive Show Exp

type LRange = Labeled Range
{-# derive DataTypeable #-}
data Range
  = RangeEnum [LExp]
  | RangeClosed LExp LExp
  | RangeOpen LExp
derive Eq Range
derive Ord Range
derive Show Range

type LCommField = Labeled CommField
{-# derive DataTypeable #-}
data CommField
  =  InComm LPattern
  | InCommGuarded LPattern LExp
  | OutComm LExp
derive Eq CommField
derive Ord CommField
derive Show CommField

type LLinkList = Labeled LinkList
{-# derive DataTypeable #-}
data LinkList
  = LinkList [LLink]
  | LinkListComprehension [LCompGen] [LLink]
derive Eq LinkList
derive Ord LinkList
derive Show LinkList

type LLink = Labeled Link
{-# derive DataTypeable #-}
data Link = Link LExp LExp
derive Eq Link
derive Ord Link
derive Show Link

type LRename = Labeled Rename
{-# derive DataTypeable #-}
data Rename = Rename LExp LExp
derive Eq Rename
derive Ord Rename
derive Show Rename

type LBuiltIn = Labeled BuiltIn
{-# derive DataTypeable #-}
data BuiltIn = BuiltIn Const
derive Eq BuiltIn
derive Ord BuiltIn
derive Show BuiltIn

lBuiltInToConst :: LBuiltIn -> Const
lBuiltInToConst = h . Labeled.unLabel where
  h (BuiltIn c) = c

type LCompGenList = Labeled [LCompGen]
type LCompGen = Labeled CompGen
{-# derive DataTypeable #-}
data CompGen
  = Generator LPattern LExp
  | Guard LExp
derive Eq CompGen
derive Ord CompGen
derive Show CompGen

type LPattern = Labeled Pattern
{-# derive DataTypeable #-}
data Pattern
  = IntPat Integer
  | TruePat
  | FalsePat
  | WildCard
  | Also [LPattern]
  | Append [LPattern]
  | DotPat [LPattern]
  | SingleSetPat LPattern
  | EmptySetPat
  | ListEnumPat [LPattern]
  | TuplePat [LPattern]
-- ConstrPat is generated by renaming
  | ConstrPat LIdent
-- This the result of pattern-match-compilation.
  | VarPat LIdent
  | Selectors { --origPat :: LPattern
 -- fixme: This creates an infinite tree with SYB everywehre'
                selectors :: Array Int Selector
               ,idents :: Array Int (Maybe LIdent) }
  | Selector Selector (Maybe LIdent)
derive Eq Pattern
derive Ord Pattern
derive Show Pattern

{- A Selector is a path in a Pattern/Expression. -}
{-# derive DataTypeable #-}
data Selector
  = IntSel Integer
  | TrueSel
  | FalseSel
  | SelectThis
  | ConstrSel UniqueIdent  
  | DotSel Int Selector
  | SingleSetSel Selector
  | EmptySetSel
  | TupleLengthSel Int Selector
  | TupleIthSel Int Selector
  | ListLengthSel Int Selector
  | ListIthSel Int Selector
  | HeadSel Selector
  | HeadNSel Int Selector
  | PrefixSel Int Int Selector
  | TailSel Selector
  | SliceSel Int Int Selector
  | SuffixSel Int Int Selector
derive Eq Selector
derive Ord Selector
derive Show Selector

type LDecl = Labeled Decl
{-# derive DataTypeable #-}
data Decl
  = PatBind LPattern LExp -- x = x+1
  | FunBind LIdent [FunCase] -- f(<>)  = <>
  | Assert LAssertDecl -- assert P [T= Q
  | Transparent [LIdent] -- transparent P
  | SubType LIdent [LConstructor]
  | DataType LIdent [LConstructor] -- datatype D = A | B.S.S | C.(S,S)
  | NameType LIdent LTypeDef -- nametype S = {1..2}
  | Channel [LIdent] (Maybe LTypeDef) -- channel x:D
  | Print LExp -- print (x+1)
derive Show Decl
derive Eq Decl
derive Ord Decl

{-
We want to use                1) type FunArgs = [LPattern]
it is not clear why we used   2) type FunArgs = [[LPattern]].
If 1) works in the interpreter, we will refactor
Renaming, and the Prolog interface to 1).
For now we just patch the AST just before PatternCompilation.
-}
type FunArgs = [[LPattern]]
{-# derive DataTypeable #-}
data FunCase
  = FunCase FunArgs LExp
  | FunCaseI [LPattern] LExp
derive Eq FunCase
derive Ord FunCase
derive Show FunCase

--type LTypeDef = Labeled TypeDef
{-data TypeDef
  = TypeTuple [LExp]
  | TypeDot [LExp]
derive Eq undefined
derive Ord undefined
derive Show undefined
derive Typeable undefined
derive Data undefined
-}
type LTypeDef = Labeled TypeDef
{-# derive DataTypeable #-}
data TypeDef
  = TypeDot [LNATuples] -- a.(b,c).d.(e,f,g)
derive Eq TypeDef
derive Ord TypeDef
derive Show TypeDef

type LNATuples = Labeled NATuples
{-# derive DataTypeable #-}
data NATuples
  = TypeTuple [LExp]
  | SingleValue LExp
derive Eq NATuples
derive Ord NATuples
derive Show NATuples

type LConstructor = Labeled Constructor
{-# derive DataTypeable #-}
data Constructor
  = Constructor LIdent (Maybe LTypeDef) 
derive Eq Constructor
derive Ord Constructor
derive Show Constructor

withLabel :: ( NodeId -> a -> b ) -> Labeled a -> Labeled b
withLabel f x = x.{unLabel = f (x.nodeId) (x.unLabel) }

type LAssertDecl = Labeled AssertDecl
{-# derive DataTypeable #-}
data AssertDecl
  = AssertBool LExp
  | AssertRefine     Bool LExp LRefineOp    LExp
  | AssertLTLCTL     Bool LExp LFormulaType String
  | AssertTauPrio    Bool LExp LTauRefineOp LExp LExp
  | AssertModelCheck Bool LExp LFDRModels (Maybe LFdrExt)
derive Eq AssertDecl
derive Ord AssertDecl
derive Show AssertDecl

type LFDRModels = Labeled FDRModels
{-# derive DataTypeable #-}
data FDRModels
  = DeadlockFree
  | Deterministic
  | LivelockFree
derive Eq FDRModels
derive Ord FDRModels
derive Show FDRModels

type LFdrExt = Labeled FdrExt
{-# derive DataTypeable #-}
data FdrExt 
  = F 
  | FD
  | T
derive Eq FdrExt
derive Ord FdrExt
derive Show FdrExt

type LTauRefineOp = Labeled TauRefineOp 
{-# derive DataTypeable #-}
data TauRefineOp
  = TauTrace
  | TauRefine
derive Eq TauRefineOp
derive Ord TauRefineOp
derive Show TauRefineOp

type LRefineOp = Labeled RefineOp
{-# derive DataTypeable #-}
data RefineOp 
  = Trace
  | Failure
  | FailureDivergence
  | RefusalTesting
  | RefusalTestingDiv
  | RevivalTesting
  | RevivalTestingDiv
  | TauPriorityOp
derive Eq RefineOp
derive Ord RefineOp
derive Show RefineOp

type LFormulaType = Labeled FormulaType
{-# derive DataTypeable #-}
data FormulaType
  = LTL
  | CTL
derive Eq FormulaType
derive Ord FormulaType
derive Show FormulaType

{-# derive DataTypeable #-}
data Const
  = F_true
  | F_false
  | F_not
  | F_and
  | F_or
  -- | F_union
  -- | F_inter
  -- | F_diff
  -- | F_Union
  -- | F_Inter
  -- | F_member
  -- | F_card
  -- | F_empty
  -- | F_set
  -- | F_seq
  -- | F_Set
  -- | F_Seq
  -- | F_null
  -- | F_head
  -- | F_tail
  -- | F_concat -- fix this: Confusing F_Concat.
  -- | F_elem
  -- | F_length
  | F_STOP
  | F_SKIP
  | F_Events
  | F_Int
  | F_Bool
  | F_CHAOS
  | F_Concat -- fix this: Confusing F_concat.
  | F_Len2
  | F_Mult
  | F_Div
  | F_Mod
  | F_Add
  | F_Sub
  | F_Eq
  | F_NEq
  | F_GE
  | F_LE
  | F_LT
  | F_GT
  | F_Guard
  | F_Sequential
  | F_Interrupt
  | F_ExtChoice
  | F_IntChoice
  | F_Hiding
  | F_Timeout
  | F_Interleave
derive Eq Const
derive Ord Const
derive Show Const

type Pragma = String
type LocComment = (Comment, SrcLoc)
{-# derive DataTypeable #-}
data Comment
  = LineComment String
  | BlockComment String
  | PragmaComment Pragma
derive Eq Comment
derive Ord Comment
derive Show Comment

-- Code generated by DataDeriver
tc_NodeId :: TyCon
tc_NodeId = mkTyCon3 "Language.CSPM" "AST" "NodeId"
instance Typeable (NodeId ) where
    typeOf _ = mkTyConApp tc_NodeId []
con_NodeId_NodeId :: Constr
con_NodeId_NodeId = mkConstr ty_NodeId "con_NodeId_NodeId" [] Prefix
ty_NodeId :: DataType
ty_NodeId = mkDataType "Language.CSPM.AST.NodeId" [con_NodeId_NodeId]
instance Data (NodeId ) where
    toConstr (NodeId _) = con_NodeId_NodeId
    dataTypeOf _ = ty_NodeId
    gunfold k z c = case constrIndex c of
                         1 -> k (z NodeId)
                         _ -> error "gunfold(NodeId)"
    gfoldl f z x = case x of
                         (NodeId a1) -> (z NodeId) `f` a1

tc_Labeled :: TyCon
tc_Labeled = mkTyCon3 "Language.CSPM" "AST" "Labeled"
instance (Typeable a1) => Typeable (Labeled a1 ) where
    typeOf = typeOfDefault
instance Typeable1 Labeled where
  typeOf1 _ = mkTyConApp tc_Labeled []
con_Labeled_Labeled :: Constr
con_Labeled_Labeled = mkConstr ty_Labeled "con_Labeled_Labeled" [] Prefix
ty_Labeled :: DataType
ty_Labeled = mkDataType "Language.CSPM.AST.Labeled" [con_Labeled_Labeled]
instance (Data a1) => Data (Labeled a1 ) where
    toConstr (Labeled _ _ _) = con_Labeled_Labeled
    dataTypeOf _ = ty_Labeled
    gunfold k z c = case constrIndex c of
                         1 -> k (k (k (z Labeled)))
                         _ -> error "gunfold(Labeled)"
    gfoldl f z x = case x of
                         (Labeled a1 a2 a3) -> (((z Labeled) `f` a1) `f` a2) `f` a3

tc_Ident :: TyCon
tc_Ident = mkTyCon3 "Language.CSPM" "AST" "Ident"
instance Typeable (Ident ) where
    typeOf _ = mkTyConApp tc_Ident []
con_Ident_Ident :: Constr
con_Ident_Ident = mkConstr ty_Ident "con_Ident_Ident" [] Prefix
con_Ident_UIdent :: Constr
con_Ident_UIdent = mkConstr ty_Ident "con_Ident_UIdent" [] Prefix
ty_Ident :: DataType
ty_Ident = mkDataType "Language.CSPM.AST.Ident" [con_Ident_Ident, con_Ident_UIdent]
instance Data (Ident ) where
    toConstr (Ident _) = con_Ident_Ident
    toConstr (UIdent _) = con_Ident_UIdent
    dataTypeOf _ = ty_Ident
    gunfold k z c = case constrIndex c of
                         1 -> k (z Ident)
                         2 -> k (z UIdent)
                         _ -> error "gunfold(Ident)"
    gfoldl f z x = case x of
                         (Ident a1) -> (z Ident) `f` a1
                         (UIdent a1) -> (z UIdent) `f` a1

tc_UniqueIdent :: TyCon
tc_UniqueIdent = mkTyCon3 "Language.CSPM" "AST" "UniqueIdent"
instance Typeable (UniqueIdent ) where
    typeOf _ = mkTyConApp tc_UniqueIdent []
con_UniqueIdent_UniqueIdent :: Constr
con_UniqueIdent_UniqueIdent = mkConstr ty_UniqueIdent "con_UniqueIdent_UniqueIdent" [] Prefix
ty_UniqueIdent :: DataType
ty_UniqueIdent = mkDataType "Language.CSPM.AST.UniqueIdent" [con_UniqueIdent_UniqueIdent]
instance Data (UniqueIdent ) where
    toConstr (UniqueIdent _ _ _ _ _ _ _ _) = con_UniqueIdent_UniqueIdent
    dataTypeOf _ = ty_UniqueIdent
    gunfold k z c = case constrIndex c of
                         1 -> k (k (k (k (k (k (k (k (z UniqueIdent))))))))
                         _ -> error "gunfold(UniqueIdent)"
    gfoldl f z x = case x of
                         (UniqueIdent a1 a2 a3 a4 a5 a6 a7 a8) -> ((((((((z UniqueIdent) `f` a1) `f` a2) `f` a3) `f` a4) `f` a5) `f` a6) `f` a7) `f` a8

tc_IDType :: TyCon
tc_IDType = mkTyCon3 "Language.CSPM" "AST" "IDType"
instance Typeable (IDType ) where
    typeOf _ = mkTyConApp tc_IDType []
con_IDType_VarID :: Constr
con_IDType_VarID = mkConstr ty_IDType "con_IDType_VarID" [] Prefix
con_IDType_ChannelID :: Constr
con_IDType_ChannelID = mkConstr ty_IDType "con_IDType_ChannelID" [] Prefix
con_IDType_NameTypeID :: Constr
con_IDType_NameTypeID = mkConstr ty_IDType "con_IDType_NameTypeID" [] Prefix
con_IDType_FunID :: Constr
con_IDType_FunID = mkConstr ty_IDType "con_IDType_FunID" [] Prefix
con_IDType_ConstrID :: Constr
con_IDType_ConstrID = mkConstr ty_IDType "con_IDType_ConstrID" [] Prefix
con_IDType_DataTypeID :: Constr
con_IDType_DataTypeID = mkConstr ty_IDType "con_IDType_DataTypeID" [] Prefix
con_IDType_TransparentID :: Constr
con_IDType_TransparentID = mkConstr ty_IDType "con_IDType_TransparentID" [] Prefix
con_IDType_BuiltInID :: Constr
con_IDType_BuiltInID = mkConstr ty_IDType "con_IDType_BuiltInID" [] Prefix
ty_IDType :: DataType
ty_IDType = mkDataType "Language.CSPM.AST.IDType" [con_IDType_VarID, con_IDType_ChannelID, con_IDType_NameTypeID, con_IDType_FunID, con_IDType_ConstrID, con_IDType_DataTypeID, con_IDType_TransparentID, con_IDType_BuiltInID]
instance Data (IDType ) where
    toConstr (VarID) = con_IDType_VarID
    toConstr (ChannelID) = con_IDType_ChannelID
    toConstr (NameTypeID) = con_IDType_NameTypeID
    toConstr (FunID) = con_IDType_FunID
    toConstr (ConstrID) = con_IDType_ConstrID
    toConstr (DataTypeID) = con_IDType_DataTypeID
    toConstr (TransparentID) = con_IDType_TransparentID
    toConstr (BuiltInID) = con_IDType_BuiltInID
    dataTypeOf _ = ty_IDType
    gunfold k z c = case constrIndex c of
                         1 -> z VarID
                         2 -> z ChannelID
                         3 -> z NameTypeID
                         4 -> z FunID
                         5 -> z ConstrID
                         6 -> z DataTypeID
                         7 -> z TransparentID
                         8 -> z BuiltInID
                         _ -> error "gunfold(IDType)"
    gfoldl f z x = case x of
                         (VarID) -> z VarID
                         (ChannelID) -> z ChannelID
                         (NameTypeID) -> z NameTypeID
                         (FunID) -> z FunID
                         (ConstrID) -> z ConstrID
                         (DataTypeID) -> z DataTypeID
                         (TransparentID) -> z TransparentID
                         (BuiltInID) -> z BuiltInID

tc_PrologMode :: TyCon
tc_PrologMode = mkTyCon3 "Language.CSPM" "AST" "PrologMode"
instance Typeable (PrologMode ) where
    typeOf _ = mkTyConApp tc_PrologMode []
con_PrologMode_PrologGround :: Constr
con_PrologMode_PrologGround = mkConstr ty_PrologMode "con_PrologMode_PrologGround" [] Prefix
con_PrologMode_PrologVariable :: Constr
con_PrologMode_PrologVariable = mkConstr ty_PrologMode "con_PrologMode_PrologVariable" [] Prefix
ty_PrologMode :: DataType
ty_PrologMode = mkDataType "Language.CSPM.AST.PrologMode" [con_PrologMode_PrologGround, con_PrologMode_PrologVariable]
instance Data (PrologMode ) where
    toConstr (PrologGround) = con_PrologMode_PrologGround
    toConstr (PrologVariable) = con_PrologMode_PrologVariable
    dataTypeOf _ = ty_PrologMode
    gunfold k z c = case constrIndex c of
                         1 -> z PrologGround
                         2 -> z PrologVariable
                         _ -> error "gunfold(PrologMode)"
    gfoldl f z x = case x of
                         (PrologGround) -> z PrologGround
                         (PrologVariable) -> z PrologVariable

tc_BindType :: TyCon
tc_BindType = mkTyCon3 "Language.CSPM" "AST" "BindType"
instance Typeable (BindType ) where
    typeOf _ = mkTyConApp tc_BindType []
con_BindType_LetBound :: Constr
con_BindType_LetBound = mkConstr ty_BindType "con_BindType_LetBound" [] Prefix
con_BindType_NotLetBound :: Constr
con_BindType_NotLetBound = mkConstr ty_BindType "con_BindType_NotLetBound" [] Prefix
ty_BindType :: DataType
ty_BindType = mkDataType "Language.CSPM.AST.BindType" [con_BindType_LetBound, con_BindType_NotLetBound]
instance Data (BindType ) where
    toConstr (LetBound) = con_BindType_LetBound
    toConstr (NotLetBound) = con_BindType_NotLetBound
    dataTypeOf _ = ty_BindType
    gunfold k z c = case constrIndex c of
                         1 -> z LetBound
                         2 -> z NotLetBound
                         _ -> error "gunfold(BindType)"
    gfoldl f z x = case x of
                         (LetBound) -> z LetBound
                         (NotLetBound) -> z NotLetBound

tc_Module :: TyCon
tc_Module = mkTyCon3 "Language.CSPM" "AST" "Module"
instance (Typeable a1) => Typeable (Module a1 ) where
    typeOf = typeOfDefault
instance Typeable1 Module where
  typeOf1 _ = mkTyConApp tc_Module []
con_Module_Module :: Constr
con_Module_Module = mkConstr ty_Module "con_Module_Module" [] Prefix
ty_Module :: DataType
ty_Module = mkDataType "Language.CSPM.AST.Module" [con_Module_Module]
instance (Data a1) => Data (Module a1 ) where
    toConstr (Module _ _ _ _ _) = con_Module_Module
    dataTypeOf _ = ty_Module
    gunfold k z c = case constrIndex c of
                         1 -> k (k (k (k (k (z Module)))))
                         _ -> error "gunfold(Module)"
    gfoldl f z x = case x of
                         (Module a1 a2 a3 a4 a5) -> (((((z Module) `f` a1) `f` a2) `f` a3) `f` a4) `f` a5

tc_FromParser :: TyCon
tc_FromParser = mkTyCon3 "Language.CSPM" "AST" "FromParser"
instance Typeable (FromParser ) where
    typeOf _ = mkTyConApp tc_FromParser []
con_FromParser_FromParser :: Constr
con_FromParser_FromParser = mkConstr ty_FromParser "con_FromParser_FromParser" [] Prefix
ty_FromParser :: DataType
ty_FromParser = mkDataType "Language.CSPM.AST.FromParser" [con_FromParser_FromParser]
instance Data (FromParser ) where
    toConstr (FromParser) = con_FromParser_FromParser
    dataTypeOf _ = ty_FromParser
    gunfold k z c = case constrIndex c of
                         1 -> z FromParser
                         _ -> error "gunfold(FromParser)"
    gfoldl f z x = case x of
                         (FromParser) -> z FromParser

tc_Exp :: TyCon
tc_Exp = mkTyCon3 "HHU" "Test1" "Exp"
instance Typeable (Exp ) where
    typeOf _ = mkTyConApp tc_Exp []
con_Exp_Var :: Constr
con_Exp_Var = mkConstr ty_Exp "con_Exp_Var" [] Prefix
con_Exp_IntExp :: Constr
con_Exp_IntExp = mkConstr ty_Exp "con_Exp_IntExp" [] Prefix
con_Exp_SetExp :: Constr
con_Exp_SetExp = mkConstr ty_Exp "con_Exp_SetExp" [] Prefix
con_Exp_ListExp :: Constr
con_Exp_ListExp = mkConstr ty_Exp "con_Exp_ListExp" [] Prefix
con_Exp_ClosureComprehension :: Constr
con_Exp_ClosureComprehension = mkConstr ty_Exp "con_Exp_ClosureComprehension" [] Prefix
con_Exp_Let :: Constr
con_Exp_Let = mkConstr ty_Exp "con_Exp_Let" [] Prefix
con_Exp_Ifte :: Constr
con_Exp_Ifte = mkConstr ty_Exp "con_Exp_Ifte" [] Prefix
con_Exp_CallFunction :: Constr
con_Exp_CallFunction = mkConstr ty_Exp "con_Exp_CallFunction" [] Prefix
con_Exp_CallBuiltIn :: Constr
con_Exp_CallBuiltIn = mkConstr ty_Exp "con_Exp_CallBuiltIn" [] Prefix
con_Exp_Lambda :: Constr
con_Exp_Lambda = mkConstr ty_Exp "con_Exp_Lambda" [] Prefix
con_Exp_Stop :: Constr
con_Exp_Stop = mkConstr ty_Exp "con_Exp_Stop" [] Prefix
con_Exp_Skip :: Constr
con_Exp_Skip = mkConstr ty_Exp "con_Exp_Skip" [] Prefix
con_Exp_CTrue :: Constr
con_Exp_CTrue = mkConstr ty_Exp "con_Exp_CTrue" [] Prefix
con_Exp_CFalse :: Constr
con_Exp_CFalse = mkConstr ty_Exp "con_Exp_CFalse" [] Prefix
con_Exp_Events :: Constr
con_Exp_Events = mkConstr ty_Exp "con_Exp_Events" [] Prefix
con_Exp_BoolSet :: Constr
con_Exp_BoolSet = mkConstr ty_Exp "con_Exp_BoolSet" [] Prefix
con_Exp_IntSet :: Constr
con_Exp_IntSet = mkConstr ty_Exp "con_Exp_IntSet" [] Prefix
con_Exp_TupleExp :: Constr
con_Exp_TupleExp = mkConstr ty_Exp "con_Exp_TupleExp" [] Prefix
con_Exp_Parens :: Constr
con_Exp_Parens = mkConstr ty_Exp "con_Exp_Parens" [] Prefix
con_Exp_AndExp :: Constr
con_Exp_AndExp = mkConstr ty_Exp "con_Exp_AndExp" [] Prefix
con_Exp_OrExp :: Constr
con_Exp_OrExp = mkConstr ty_Exp "con_Exp_OrExp" [] Prefix
con_Exp_NotExp :: Constr
con_Exp_NotExp = mkConstr ty_Exp "con_Exp_NotExp" [] Prefix
con_Exp_NegExp :: Constr
con_Exp_NegExp = mkConstr ty_Exp "con_Exp_NegExp" [] Prefix
con_Exp_Fun1 :: Constr
con_Exp_Fun1 = mkConstr ty_Exp "con_Exp_Fun1" [] Prefix
con_Exp_Fun2 :: Constr
con_Exp_Fun2 = mkConstr ty_Exp "con_Exp_Fun2" [] Prefix
con_Exp_DotTuple :: Constr
con_Exp_DotTuple = mkConstr ty_Exp "con_Exp_DotTuple" [] Prefix
con_Exp_Closure :: Constr
con_Exp_Closure = mkConstr ty_Exp "con_Exp_Closure" [] Prefix
con_Exp_ProcSharing :: Constr
con_Exp_ProcSharing = mkConstr ty_Exp "con_Exp_ProcSharing" [] Prefix
con_Exp_ProcAParallel :: Constr
con_Exp_ProcAParallel = mkConstr ty_Exp "con_Exp_ProcAParallel" [] Prefix
con_Exp_ProcLinkParallel :: Constr
con_Exp_ProcLinkParallel = mkConstr ty_Exp "con_Exp_ProcLinkParallel" [] Prefix
con_Exp_ProcRenaming :: Constr
con_Exp_ProcRenaming = mkConstr ty_Exp "con_Exp_ProcRenaming" [] Prefix
con_Exp_ProcException :: Constr
con_Exp_ProcException = mkConstr ty_Exp "con_Exp_ProcException" [] Prefix
con_Exp_ProcRepSequence :: Constr
con_Exp_ProcRepSequence = mkConstr ty_Exp "con_Exp_ProcRepSequence" [] Prefix
con_Exp_ProcRepInternalChoice :: Constr
con_Exp_ProcRepInternalChoice = mkConstr ty_Exp "con_Exp_ProcRepInternalChoice" [] Prefix
con_Exp_ProcRepExternalChoice :: Constr
con_Exp_ProcRepExternalChoice = mkConstr ty_Exp "con_Exp_ProcRepExternalChoice" [] Prefix
con_Exp_ProcRepInterleave :: Constr
con_Exp_ProcRepInterleave = mkConstr ty_Exp "con_Exp_ProcRepInterleave" [] Prefix
con_Exp_ProcRepAParallel :: Constr
con_Exp_ProcRepAParallel = mkConstr ty_Exp "con_Exp_ProcRepAParallel" [] Prefix
con_Exp_ProcRepLinkParallel :: Constr
con_Exp_ProcRepLinkParallel = mkConstr ty_Exp "con_Exp_ProcRepLinkParallel" [] Prefix
con_Exp_ProcRepSharing :: Constr
con_Exp_ProcRepSharing = mkConstr ty_Exp "con_Exp_ProcRepSharing" [] Prefix
con_Exp_PrefixExp :: Constr
con_Exp_PrefixExp = mkConstr ty_Exp "con_Exp_PrefixExp" [] Prefix
con_Exp_PrefixI :: Constr
con_Exp_PrefixI = mkConstr ty_Exp "con_Exp_PrefixI" [] Prefix
con_Exp_LetI :: Constr
con_Exp_LetI = mkConstr ty_Exp "con_Exp_LetI" [] Prefix
con_Exp_LambdaI :: Constr
con_Exp_LambdaI = mkConstr ty_Exp "con_Exp_LambdaI" [] Prefix
con_Exp_ExprWithFreeNames :: Constr
con_Exp_ExprWithFreeNames = mkConstr ty_Exp "con_Exp_ExprWithFreeNames" [] Prefix
ty_Exp :: DataType
ty_Exp = mkDataType "HHU.Test1.Exp" [con_Exp_Var, con_Exp_IntExp, con_Exp_SetExp, con_Exp_ListExp, con_Exp_ClosureComprehension, con_Exp_Let, con_Exp_Ifte, con_Exp_CallFunction, con_Exp_CallBuiltIn, con_Exp_Lambda, con_Exp_Stop, con_Exp_Skip, con_Exp_CTrue, con_Exp_CFalse, con_Exp_Events, con_Exp_BoolSet, con_Exp_IntSet, con_Exp_TupleExp, con_Exp_Parens, con_Exp_AndExp, con_Exp_OrExp, con_Exp_NotExp, con_Exp_NegExp, con_Exp_Fun1, con_Exp_Fun2, con_Exp_DotTuple, con_Exp_Closure, con_Exp_ProcSharing, con_Exp_ProcAParallel, con_Exp_ProcLinkParallel, con_Exp_ProcRenaming, con_Exp_ProcException, con_Exp_ProcRepSequence, con_Exp_ProcRepInternalChoice, con_Exp_ProcRepExternalChoice, con_Exp_ProcRepInterleave, con_Exp_ProcRepAParallel, con_Exp_ProcRepLinkParallel, con_Exp_ProcRepSharing, con_Exp_PrefixExp, con_Exp_PrefixI, con_Exp_LetI, con_Exp_LambdaI, con_Exp_ExprWithFreeNames]
instance Data (Exp ) where
    toConstr (Var _) = con_Exp_Var
    toConstr (IntExp _) = con_Exp_IntExp
    toConstr (SetExp _ _) = con_Exp_SetExp
    toConstr (ListExp _ _) = con_Exp_ListExp
    toConstr (ClosureComprehension _) = con_Exp_ClosureComprehension
    toConstr (Let _ _) = con_Exp_Let
    toConstr (Ifte _ _ _) = con_Exp_Ifte
    toConstr (CallFunction _ _) = con_Exp_CallFunction
    toConstr (CallBuiltIn _ _) = con_Exp_CallBuiltIn
    toConstr (Lambda _ _) = con_Exp_Lambda
    toConstr (Stop) = con_Exp_Stop
    toConstr (Skip) = con_Exp_Skip
    toConstr (CTrue) = con_Exp_CTrue
    toConstr (CFalse) = con_Exp_CFalse
    toConstr (Events) = con_Exp_Events
    toConstr (BoolSet) = con_Exp_BoolSet
    toConstr (IntSet) = con_Exp_IntSet
    toConstr (TupleExp _) = con_Exp_TupleExp
    toConstr (Parens _) = con_Exp_Parens
    toConstr (AndExp _ _) = con_Exp_AndExp
    toConstr (OrExp _ _) = con_Exp_OrExp
    toConstr (NotExp _) = con_Exp_NotExp
    toConstr (NegExp _) = con_Exp_NegExp
    toConstr (Fun1 _ _) = con_Exp_Fun1
    toConstr (Fun2 _ _ _) = con_Exp_Fun2
    toConstr (DotTuple _) = con_Exp_DotTuple
    toConstr (Closure _) = con_Exp_Closure
    toConstr (ProcSharing _ _ _) = con_Exp_ProcSharing
    toConstr (ProcAParallel _ _ _ _) = con_Exp_ProcAParallel
    toConstr (ProcLinkParallel _ _ _) = con_Exp_ProcLinkParallel
    toConstr (ProcRenaming _ _ _) = con_Exp_ProcRenaming
    toConstr (ProcException _ _ _) = con_Exp_ProcException
    toConstr (ProcRepSequence _ _) = con_Exp_ProcRepSequence
    toConstr (ProcRepInternalChoice _ _) = con_Exp_ProcRepInternalChoice
    toConstr (ProcRepExternalChoice _ _) = con_Exp_ProcRepExternalChoice
    toConstr (ProcRepInterleave _ _) = con_Exp_ProcRepInterleave
    toConstr (ProcRepAParallel _ _ _) = con_Exp_ProcRepAParallel
    toConstr (ProcRepLinkParallel _ _ _) = con_Exp_ProcRepLinkParallel
    toConstr (ProcRepSharing _ _ _) = con_Exp_ProcRepSharing
    toConstr (PrefixExp _ _ _) = con_Exp_PrefixExp
    toConstr (PrefixI _ _ _ _) = con_Exp_PrefixI
    toConstr (LetI _ _ _) = con_Exp_LetI
    toConstr (LambdaI _ _ _) = con_Exp_LambdaI
    toConstr (ExprWithFreeNames _ _) = con_Exp_ExprWithFreeNames
    dataTypeOf _ = ty_Exp
    gunfold k z c = case constrIndex c of
                         1 -> k (z Var)
                         2 -> k (z IntExp)
                         3 -> k (k (z SetExp))
                         4 -> k (k (z ListExp))
                         5 -> k (z ClosureComprehension)
                         6 -> k (k (z Let))
                         7 -> k (k (k (z Ifte)))
                         8 -> k (k (z CallFunction))
                         9 -> k (k (z CallBuiltIn))
                         10 -> k (k (z Lambda))
                         11 -> z Stop
                         12 -> z Skip
                         13 -> z CTrue
                         14 -> z CFalse
                         15 -> z Events
                         16 -> z BoolSet
                         17 -> z IntSet
                         18 -> k (z TupleExp)
                         19 -> k (z Parens)
                         20 -> k (k (z AndExp))
                         21 -> k (k (z OrExp))
                         22 -> k (z NotExp)
                         23 -> k (z NegExp)
                         24 -> k (k (z Fun1))
                         25 -> k (k (k (z Fun2)))
                         26 -> k (z DotTuple)
                         27 -> k (z Closure)
                         28 -> k (k (k (z ProcSharing)))
                         29 -> k (k (k (k (z ProcAParallel))))
                         30 -> k (k (k (z ProcLinkParallel)))
                         31 -> k (k (k (z ProcRenaming)))
                         32 -> k (k (k (z ProcException)))
                         33 -> k (k (z ProcRepSequence))
                         34 -> k (k (z ProcRepInternalChoice))
                         35 -> k (k (z ProcRepExternalChoice))
                         36 -> k (k (z ProcRepInterleave))
                         37 -> k (k (k (z ProcRepAParallel)))
                         38 -> k (k (k (z ProcRepLinkParallel)))
                         39 -> k (k (k (z ProcRepSharing)))
                         40 -> k (k (k (z PrefixExp)))
                         41 -> k (k (k (k (z PrefixI))))
                         42 -> k (k (k (z LetI)))
                         43 -> k (k (k (z LambdaI)))
                         44 -> k (k (z ExprWithFreeNames))
                         _ -> error "gunfold(Exp)"
    gfoldl f z x = case x of
                         (Var a1) -> (z Var) `f` a1
                         (IntExp a1) -> (z IntExp) `f` a1
                         (SetExp a1 a2) -> ((z SetExp) `f` a1) `f` a2
                         (ListExp a1 a2) -> ((z ListExp) `f` a1) `f` a2
                         (ClosureComprehension a1) -> (z ClosureComprehension) `f` a1
                         (Let a1 a2) -> ((z Let) `f` a1) `f` a2
                         (Ifte a1 a2 a3) -> (((z Ifte) `f` a1) `f` a2) `f` a3
                         (CallFunction a1 a2) -> ((z CallFunction) `f` a1) `f` a2
                         (CallBuiltIn a1 a2) -> ((z CallBuiltIn) `f` a1) `f` a2
                         (Lambda a1 a2) -> ((z Lambda) `f` a1) `f` a2
                         (Stop) -> z Stop
                         (Skip) -> z Skip
                         (CTrue) -> z CTrue
                         (CFalse) -> z CFalse
                         (Events) -> z Events
                         (BoolSet) -> z BoolSet
                         (IntSet) -> z IntSet
                         (TupleExp a1) -> (z TupleExp) `f` a1
                         (Parens a1) -> (z Parens) `f` a1
                         (AndExp a1 a2) -> ((z AndExp) `f` a1) `f` a2
                         (OrExp a1 a2) -> ((z OrExp) `f` a1) `f` a2
                         (NotExp a1) -> (z NotExp) `f` a1
                         (NegExp a1) -> (z NegExp) `f` a1
                         (Fun1 a1 a2) -> ((z Fun1) `f` a1) `f` a2
                         (Fun2 a1 a2 a3) -> (((z Fun2) `f` a1) `f` a2) `f` a3
                         (DotTuple a1) -> (z DotTuple) `f` a1
                         (Closure a1) -> (z Closure) `f` a1
                         (ProcSharing a1 a2 a3) -> (((z ProcSharing) `f` a1) `f` a2) `f` a3
                         (ProcAParallel a1 a2 a3 a4) -> ((((z ProcAParallel) `f` a1) `f` a2) `f` a3) `f` a4
                         (ProcLinkParallel a1 a2 a3) -> (((z ProcLinkParallel) `f` a1) `f` a2) `f` a3
                         (ProcRenaming a1 a2 a3) -> (((z ProcRenaming) `f` a1) `f` a2) `f` a3
                         (ProcException a1 a2 a3) -> (((z ProcException) `f` a1) `f` a2) `f` a3
                         (ProcRepSequence a1 a2) -> ((z ProcRepSequence) `f` a1) `f` a2
                         (ProcRepInternalChoice a1 a2) -> ((z ProcRepInternalChoice) `f` a1) `f` a2
                         (ProcRepExternalChoice a1 a2) -> ((z ProcRepExternalChoice) `f` a1) `f` a2
                         (ProcRepInterleave a1 a2) -> ((z ProcRepInterleave) `f` a1) `f` a2
                         (ProcRepAParallel a1 a2 a3) -> (((z ProcRepAParallel) `f` a1) `f` a2) `f` a3
                         (ProcRepLinkParallel a1 a2 a3) -> (((z ProcRepLinkParallel) `f` a1) `f` a2) `f` a3
                         (ProcRepSharing a1 a2 a3) -> (((z ProcRepSharing) `f` a1) `f` a2) `f` a3
                         (PrefixExp a1 a2 a3) -> (((z PrefixExp) `f` a1) `f` a2) `f` a3
                         (PrefixI a1 a2 a3 a4) -> ((((z PrefixI) `f` a1) `f` a2) `f` a3) `f` a4
                         (LetI a1 a2 a3) -> (((z LetI) `f` a1) `f` a2) `f` a3
                         (LambdaI a1 a2 a3) -> (((z LambdaI) `f` a1) `f` a2) `f` a3
                         (ExprWithFreeNames a1 a2) -> ((z ExprWithFreeNames) `f` a1) `f` a2

tc_Range :: TyCon
tc_Range = mkTyCon3 "Language.CSPM" "AST" "Range"
instance Typeable (Range ) where
    typeOf _ = mkTyConApp tc_Range []
con_Range_RangeEnum :: Constr
con_Range_RangeEnum = mkConstr ty_Range "con_Range_RangeEnum" [] Prefix
con_Range_RangeClosed :: Constr
con_Range_RangeClosed = mkConstr ty_Range "con_Range_RangeClosed" [] Prefix
con_Range_RangeOpen :: Constr
con_Range_RangeOpen = mkConstr ty_Range "con_Range_RangeOpen" [] Prefix
ty_Range :: DataType
ty_Range = mkDataType "Language.CSPM.AST.Range" [con_Range_RangeEnum, con_Range_RangeClosed, con_Range_RangeOpen]
instance Data (Range ) where
    toConstr (RangeEnum _) = con_Range_RangeEnum
    toConstr (RangeClosed _ _) = con_Range_RangeClosed
    toConstr (RangeOpen _) = con_Range_RangeOpen
    dataTypeOf _ = ty_Range
    gunfold k z c = case constrIndex c of
                         1 -> k (z RangeEnum)
                         2 -> k (k (z RangeClosed))
                         3 -> k (z RangeOpen)
                         _ -> error "gunfold(Range)"
    gfoldl f z x = case x of
                         (RangeEnum a1) -> (z RangeEnum) `f` a1
                         (RangeClosed a1 a2) -> ((z RangeClosed) `f` a1) `f` a2
                         (RangeOpen a1) -> (z RangeOpen) `f` a1

tc_CommField :: TyCon
tc_CommField = mkTyCon3 "Language.CSPM" "AST" "CommField"
instance Typeable (CommField ) where
    typeOf _ = mkTyConApp tc_CommField []
con_CommField_InComm :: Constr
con_CommField_InComm = mkConstr ty_CommField "con_CommField_InComm" [] Prefix
con_CommField_InCommGuarded :: Constr
con_CommField_InCommGuarded = mkConstr ty_CommField "con_CommField_InCommGuarded" [] Prefix
con_CommField_OutComm :: Constr
con_CommField_OutComm = mkConstr ty_CommField "con_CommField_OutComm" [] Prefix
ty_CommField :: DataType
ty_CommField = mkDataType "Language.CSPM.AST.CommField" [con_CommField_InComm, con_CommField_InCommGuarded, con_CommField_OutComm]
instance Data (CommField ) where
    toConstr (InComm _) = con_CommField_InComm
    toConstr (InCommGuarded _ _) = con_CommField_InCommGuarded
    toConstr (OutComm _) = con_CommField_OutComm
    dataTypeOf _ = ty_CommField
    gunfold k z c = case constrIndex c of
                         1 -> k (z InComm)
                         2 -> k (k (z InCommGuarded))
                         3 -> k (z OutComm)
                         _ -> error "gunfold(CommField)"
    gfoldl f z x = case x of
                         (InComm a1) -> (z InComm) `f` a1
                         (InCommGuarded a1 a2) -> ((z InCommGuarded) `f` a1) `f` a2
                         (OutComm a1) -> (z OutComm) `f` a1

tc_LinkList :: TyCon
tc_LinkList = mkTyCon3 "Language.CSPM" "AST" "LinkList"
instance Typeable (LinkList ) where
    typeOf _ = mkTyConApp tc_LinkList []
con_LinkList_LinkList :: Constr
con_LinkList_LinkList = mkConstr ty_LinkList "con_LinkList_LinkList" [] Prefix
con_LinkList_LinkListComprehension :: Constr
con_LinkList_LinkListComprehension = mkConstr ty_LinkList "con_LinkList_LinkListComprehension" [] Prefix
ty_LinkList :: DataType
ty_LinkList = mkDataType "Language.CSPM.AST.LinkList" [con_LinkList_LinkList, con_LinkList_LinkListComprehension]
instance Data (LinkList ) where
    toConstr (LinkList _) = con_LinkList_LinkList
    toConstr (LinkListComprehension _ _) = con_LinkList_LinkListComprehension
    dataTypeOf _ = ty_LinkList
    gunfold k z c = case constrIndex c of
                         1 -> k (z LinkList)
                         2 -> k (k (z LinkListComprehension))
                         _ -> error "gunfold(LinkList)"
    gfoldl f z x = case x of
                         (LinkList a1) -> (z LinkList) `f` a1
                         (LinkListComprehension a1 a2) -> ((z LinkListComprehension) `f` a1) `f` a2

tc_Link :: TyCon
tc_Link = mkTyCon3 "Language.CSPM" "AST" "Link"
instance Typeable (Link ) where
    typeOf _ = mkTyConApp tc_Link []
con_Link_Link :: Constr
con_Link_Link = mkConstr ty_Link "con_Link_Link" [] Prefix
ty_Link :: DataType
ty_Link = mkDataType "Language.CSPM.AST.Link" [con_Link_Link]
instance Data (Link ) where
    toConstr (Link _ _) = con_Link_Link
    dataTypeOf _ = ty_Link
    gunfold k z c = case constrIndex c of
                         1 -> k (k (z Link))
                         _ -> error "gunfold(Link)"
    gfoldl f z x = case x of
                         (Link a1 a2) -> ((z Link) `f` a1) `f` a2

tc_Rename :: TyCon
tc_Rename = mkTyCon3 "Language.CSPM" "AST" "Rename"
instance Typeable (Rename ) where
    typeOf _ = mkTyConApp tc_Rename []
con_Rename_Rename :: Constr
con_Rename_Rename = mkConstr ty_Rename "con_Rename_Rename" [] Prefix
ty_Rename :: DataType
ty_Rename = mkDataType "Language.CSPM.AST.Rename" [con_Rename_Rename]
instance Data (Rename ) where
    toConstr (Rename _ _) = con_Rename_Rename
    dataTypeOf _ = ty_Rename
    gunfold k z c = case constrIndex c of
                         1 -> k (k (z Rename))
                         _ -> error "gunfold(Rename)"
    gfoldl f z x = case x of
                         (Rename a1 a2) -> ((z Rename) `f` a1) `f` a2

tc_BuiltIn :: TyCon
tc_BuiltIn = mkTyCon3 "Language.CSPM" "AST" "BuiltIn"
instance Typeable (BuiltIn ) where
    typeOf _ = mkTyConApp tc_BuiltIn []
con_BuiltIn_BuiltIn :: Constr
con_BuiltIn_BuiltIn = mkConstr ty_BuiltIn "con_BuiltIn_BuiltIn" [] Prefix
ty_BuiltIn :: DataType
ty_BuiltIn = mkDataType "Language.CSPM.AST.BuiltIn" [con_BuiltIn_BuiltIn]
instance Data (BuiltIn ) where
    toConstr (BuiltIn _) = con_BuiltIn_BuiltIn
    dataTypeOf _ = ty_BuiltIn
    gunfold k z c = case constrIndex c of
                         1 -> k (z BuiltIn)
                         _ -> error "gunfold(BuiltIn)"
    gfoldl f z x = case x of
                         (BuiltIn a1) -> (z BuiltIn) `f` a1

tc_CompGen :: TyCon
tc_CompGen = mkTyCon3 "Language.CSPM" "AST" "CompGen"
instance Typeable (CompGen ) where
    typeOf _ = mkTyConApp tc_CompGen []
con_CompGen_Generator :: Constr
con_CompGen_Generator = mkConstr ty_CompGen "con_CompGen_Generator" [] Prefix
con_CompGen_Guard :: Constr
con_CompGen_Guard = mkConstr ty_CompGen "con_CompGen_Guard" [] Prefix
ty_CompGen :: DataType
ty_CompGen = mkDataType "Language.CSPM.AST.CompGen" [con_CompGen_Generator, con_CompGen_Guard]
instance Data (CompGen ) where
    toConstr (Generator _ _) = con_CompGen_Generator
    toConstr (Guard _) = con_CompGen_Guard
    dataTypeOf _ = ty_CompGen
    gunfold k z c = case constrIndex c of
                         1 -> k (k (z Generator))
                         2 -> k (z Guard)
                         _ -> error "gunfold(CompGen)"
    gfoldl f z x = case x of
                         (Generator a1 a2) -> ((z Generator) `f` a1) `f` a2
                         (Guard a1) -> (z Guard) `f` a1

tc_Pattern :: TyCon
tc_Pattern = mkTyCon3 "Language.CSPM" "AST" "Pattern"
instance Typeable (Pattern ) where
    typeOf _ = mkTyConApp tc_Pattern []
con_Pattern_IntPat :: Constr
con_Pattern_IntPat = mkConstr ty_Pattern "con_Pattern_IntPat" [] Prefix
con_Pattern_TruePat :: Constr
con_Pattern_TruePat = mkConstr ty_Pattern "con_Pattern_TruePat" [] Prefix
con_Pattern_FalsePat :: Constr
con_Pattern_FalsePat = mkConstr ty_Pattern "con_Pattern_FalsePat" [] Prefix
con_Pattern_WildCard :: Constr
con_Pattern_WildCard = mkConstr ty_Pattern "con_Pattern_WildCard" [] Prefix
con_Pattern_Also :: Constr
con_Pattern_Also = mkConstr ty_Pattern "con_Pattern_Also" [] Prefix
con_Pattern_Append :: Constr
con_Pattern_Append = mkConstr ty_Pattern "con_Pattern_Append" [] Prefix
con_Pattern_DotPat :: Constr
con_Pattern_DotPat = mkConstr ty_Pattern "con_Pattern_DotPat" [] Prefix
con_Pattern_SingleSetPat :: Constr
con_Pattern_SingleSetPat = mkConstr ty_Pattern "con_Pattern_SingleSetPat" [] Prefix
con_Pattern_EmptySetPat :: Constr
con_Pattern_EmptySetPat = mkConstr ty_Pattern "con_Pattern_EmptySetPat" [] Prefix
con_Pattern_ListEnumPat :: Constr
con_Pattern_ListEnumPat = mkConstr ty_Pattern "con_Pattern_ListEnumPat" [] Prefix
con_Pattern_TuplePat :: Constr
con_Pattern_TuplePat = mkConstr ty_Pattern "con_Pattern_TuplePat" [] Prefix
con_Pattern_ConstrPat :: Constr
con_Pattern_ConstrPat = mkConstr ty_Pattern "con_Pattern_ConstrPat" [] Prefix
con_Pattern_VarPat :: Constr
con_Pattern_VarPat = mkConstr ty_Pattern "con_Pattern_VarPat" [] Prefix
con_Pattern_Selectors :: Constr
con_Pattern_Selectors = mkConstr ty_Pattern "con_Pattern_Selectors" [] Prefix
con_Pattern_Selector :: Constr
con_Pattern_Selector = mkConstr ty_Pattern "con_Pattern_Selector" [] Prefix
ty_Pattern :: DataType
ty_Pattern = mkDataType "Language.CSPM.AST.Pattern" [con_Pattern_IntPat, con_Pattern_TruePat, con_Pattern_FalsePat, con_Pattern_WildCard, con_Pattern_Also, con_Pattern_Append, con_Pattern_DotPat, con_Pattern_SingleSetPat, con_Pattern_EmptySetPat, con_Pattern_ListEnumPat, con_Pattern_TuplePat, con_Pattern_ConstrPat, con_Pattern_VarPat, con_Pattern_Selectors, con_Pattern_Selector]
instance Data (Pattern ) where
    toConstr (IntPat _) = con_Pattern_IntPat
    toConstr (TruePat) = con_Pattern_TruePat
    toConstr (FalsePat) = con_Pattern_FalsePat
    toConstr (WildCard) = con_Pattern_WildCard
    toConstr (Also _) = con_Pattern_Also
    toConstr (Append _) = con_Pattern_Append
    toConstr (DotPat _) = con_Pattern_DotPat
    toConstr (SingleSetPat _) = con_Pattern_SingleSetPat
    toConstr (EmptySetPat) = con_Pattern_EmptySetPat
    toConstr (ListEnumPat _) = con_Pattern_ListEnumPat
    toConstr (TuplePat _) = con_Pattern_TuplePat
    toConstr (ConstrPat _) = con_Pattern_ConstrPat
    toConstr (VarPat _) = con_Pattern_VarPat
    toConstr (Selectors _ _) = con_Pattern_Selectors
    toConstr (Selector _ _) = con_Pattern_Selector
    dataTypeOf _ = ty_Pattern
    gunfold k z c = case constrIndex c of
                         1 -> k (z IntPat)
                         2 -> z TruePat
                         3 -> z FalsePat
                         4 -> z WildCard
                         5 -> k (z Also)
                         6 -> k (z Append)
                         7 -> k (z DotPat)
                         8 -> k (z SingleSetPat)
                         9 -> z EmptySetPat
                         10 -> k (z ListEnumPat)
                         11 -> k (z TuplePat)
                         12 -> k (z ConstrPat)
                         13 -> k (z VarPat)
                         14 -> k (k (z Selectors))
                         15 -> k (k (z Selector))
                         _ -> error "gunfold(Pattern)"
    gfoldl f z x = case x of
                         (IntPat a1) -> (z IntPat) `f` a1
                         (TruePat) -> z TruePat
                         (FalsePat) -> z FalsePat
                         (WildCard) -> z WildCard
                         (Also a1) -> (z Also) `f` a1
                         (Append a1) -> (z Append) `f` a1
                         (DotPat a1) -> (z DotPat) `f` a1
                         (SingleSetPat a1) -> (z SingleSetPat) `f` a1
                         (EmptySetPat) -> z EmptySetPat
                         (ListEnumPat a1) -> (z ListEnumPat) `f` a1
                         (TuplePat a1) -> (z TuplePat) `f` a1
                         (ConstrPat a1) -> (z ConstrPat) `f` a1
                         (VarPat a1) -> (z VarPat) `f` a1
                         (Selectors a1 a2) -> ((z Selectors) `f` a1) `f` a2
                         (Selector a1 a2) -> ((z Selector) `f` a1) `f` a2

tc_Selector :: TyCon
tc_Selector = mkTyCon3 "Language.CSPM" "AST" "Selector"
instance Typeable (Selector ) where
    typeOf _ = mkTyConApp tc_Selector []
con_Selector_IntSel :: Constr
con_Selector_IntSel = mkConstr ty_Selector "con_Selector_IntSel" [] Prefix
con_Selector_TrueSel :: Constr
con_Selector_TrueSel = mkConstr ty_Selector "con_Selector_TrueSel" [] Prefix
con_Selector_FalseSel :: Constr
con_Selector_FalseSel = mkConstr ty_Selector "con_Selector_FalseSel" [] Prefix
con_Selector_SelectThis :: Constr
con_Selector_SelectThis = mkConstr ty_Selector "con_Selector_SelectThis" [] Prefix
con_Selector_ConstrSel :: Constr
con_Selector_ConstrSel = mkConstr ty_Selector "con_Selector_ConstrSel" [] Prefix
con_Selector_DotSel :: Constr
con_Selector_DotSel = mkConstr ty_Selector "con_Selector_DotSel" [] Prefix
con_Selector_SingleSetSel :: Constr
con_Selector_SingleSetSel = mkConstr ty_Selector "con_Selector_SingleSetSel" [] Prefix
con_Selector_EmptySetSel :: Constr
con_Selector_EmptySetSel = mkConstr ty_Selector "con_Selector_EmptySetSel" [] Prefix
con_Selector_TupleLengthSel :: Constr
con_Selector_TupleLengthSel = mkConstr ty_Selector "con_Selector_TupleLengthSel" [] Prefix
con_Selector_TupleIthSel :: Constr
con_Selector_TupleIthSel = mkConstr ty_Selector "con_Selector_TupleIthSel" [] Prefix
con_Selector_ListLengthSel :: Constr
con_Selector_ListLengthSel = mkConstr ty_Selector "con_Selector_ListLengthSel" [] Prefix
con_Selector_ListIthSel :: Constr
con_Selector_ListIthSel = mkConstr ty_Selector "con_Selector_ListIthSel" [] Prefix
con_Selector_HeadSel :: Constr
con_Selector_HeadSel = mkConstr ty_Selector "con_Selector_HeadSel" [] Prefix
con_Selector_HeadNSel :: Constr
con_Selector_HeadNSel = mkConstr ty_Selector "con_Selector_HeadNSel" [] Prefix
con_Selector_PrefixSel :: Constr
con_Selector_PrefixSel = mkConstr ty_Selector "con_Selector_PrefixSel" [] Prefix
con_Selector_TailSel :: Constr
con_Selector_TailSel = mkConstr ty_Selector "con_Selector_TailSel" [] Prefix
con_Selector_SliceSel :: Constr
con_Selector_SliceSel = mkConstr ty_Selector "con_Selector_SliceSel" [] Prefix
con_Selector_SuffixSel :: Constr
con_Selector_SuffixSel = mkConstr ty_Selector "con_Selector_SuffixSel" [] Prefix
ty_Selector :: DataType
ty_Selector = mkDataType "Language.CSPM.AST.Selector" [con_Selector_IntSel, con_Selector_TrueSel, con_Selector_FalseSel, con_Selector_SelectThis, con_Selector_ConstrSel, con_Selector_DotSel, con_Selector_SingleSetSel, con_Selector_EmptySetSel, con_Selector_TupleLengthSel, con_Selector_TupleIthSel, con_Selector_ListLengthSel, con_Selector_ListIthSel, con_Selector_HeadSel, con_Selector_HeadNSel, con_Selector_PrefixSel, con_Selector_TailSel, con_Selector_SliceSel, con_Selector_SuffixSel]
instance Data (Selector ) where
    toConstr (IntSel _) = con_Selector_IntSel
    toConstr (TrueSel) = con_Selector_TrueSel
    toConstr (FalseSel) = con_Selector_FalseSel
    toConstr (SelectThis) = con_Selector_SelectThis
    toConstr (ConstrSel _) = con_Selector_ConstrSel
    toConstr (DotSel _ _) = con_Selector_DotSel
    toConstr (SingleSetSel _) = con_Selector_SingleSetSel
    toConstr (EmptySetSel) = con_Selector_EmptySetSel
    toConstr (TupleLengthSel _ _) = con_Selector_TupleLengthSel
    toConstr (TupleIthSel _ _) = con_Selector_TupleIthSel
    toConstr (ListLengthSel _ _) = con_Selector_ListLengthSel
    toConstr (ListIthSel _ _) = con_Selector_ListIthSel
    toConstr (HeadSel _) = con_Selector_HeadSel
    toConstr (HeadNSel _ _) = con_Selector_HeadNSel
    toConstr (PrefixSel _ _ _) = con_Selector_PrefixSel
    toConstr (TailSel _) = con_Selector_TailSel
    toConstr (SliceSel _ _ _) = con_Selector_SliceSel
    toConstr (SuffixSel _ _ _) = con_Selector_SuffixSel
    dataTypeOf _ = ty_Selector
    gunfold k z c = case constrIndex c of
                         1 -> k (z IntSel)
                         2 -> z TrueSel
                         3 -> z FalseSel
                         4 -> z SelectThis
                         5 -> k (z ConstrSel)
                         6 -> k (k (z DotSel))
                         7 -> k (z SingleSetSel)
                         8 -> z EmptySetSel
                         9 -> k (k (z TupleLengthSel))
                         10 -> k (k (z TupleIthSel))
                         11 -> k (k (z ListLengthSel))
                         12 -> k (k (z ListIthSel))
                         13 -> k (z HeadSel)
                         14 -> k (k (z HeadNSel))
                         15 -> k (k (k (z PrefixSel)))
                         16 -> k (z TailSel)
                         17 -> k (k (k (z SliceSel)))
                         18 -> k (k (k (z SuffixSel)))
                         _ -> error "gunfold(Selector)"
    gfoldl f z x = case x of
                         (IntSel a1) -> (z IntSel) `f` a1
                         (TrueSel) -> z TrueSel
                         (FalseSel) -> z FalseSel
                         (SelectThis) -> z SelectThis
                         (ConstrSel a1) -> (z ConstrSel) `f` a1
                         (DotSel a1 a2) -> ((z DotSel) `f` a1) `f` a2
                         (SingleSetSel a1) -> (z SingleSetSel) `f` a1
                         (EmptySetSel) -> z EmptySetSel
                         (TupleLengthSel a1 a2) -> ((z TupleLengthSel) `f` a1) `f` a2
                         (TupleIthSel a1 a2) -> ((z TupleIthSel) `f` a1) `f` a2
                         (ListLengthSel a1 a2) -> ((z ListLengthSel) `f` a1) `f` a2
                         (ListIthSel a1 a2) -> ((z ListIthSel) `f` a1) `f` a2
                         (HeadSel a1) -> (z HeadSel) `f` a1
                         (HeadNSel a1 a2) -> ((z HeadNSel) `f` a1) `f` a2
                         (PrefixSel a1 a2 a3) -> (((z PrefixSel) `f` a1) `f` a2) `f` a3
                         (TailSel a1) -> (z TailSel) `f` a1
                         (SliceSel a1 a2 a3) -> (((z SliceSel) `f` a1) `f` a2) `f` a3
                         (SuffixSel a1 a2 a3) -> (((z SuffixSel) `f` a1) `f` a2) `f` a3

tc_Decl :: TyCon
tc_Decl = mkTyCon3 "Language.CSPM" "AST" "Decl"
instance Typeable (Decl ) where
    typeOf _ = mkTyConApp tc_Decl []
con_Decl_PatBind :: Constr
con_Decl_PatBind = mkConstr ty_Decl "con_Decl_PatBind" [] Prefix
con_Decl_FunBind :: Constr
con_Decl_FunBind = mkConstr ty_Decl "con_Decl_FunBind" [] Prefix
con_Decl_Assert :: Constr
con_Decl_Assert = mkConstr ty_Decl "con_Decl_Assert" [] Prefix
con_Decl_Transparent :: Constr
con_Decl_Transparent = mkConstr ty_Decl "con_Decl_Transparent" [] Prefix
con_Decl_SubType :: Constr
con_Decl_SubType = mkConstr ty_Decl "con_Decl_SubType" [] Prefix
con_Decl_DataType :: Constr
con_Decl_DataType = mkConstr ty_Decl "con_Decl_DataType" [] Prefix
con_Decl_NameType :: Constr
con_Decl_NameType = mkConstr ty_Decl "con_Decl_NameType" [] Prefix
con_Decl_Channel :: Constr
con_Decl_Channel = mkConstr ty_Decl "con_Decl_Channel" [] Prefix
con_Decl_Print :: Constr
con_Decl_Print = mkConstr ty_Decl "con_Decl_Print" [] Prefix
ty_Decl :: DataType
ty_Decl = mkDataType "Language.CSPM.AST.Decl" [con_Decl_PatBind, con_Decl_FunBind, con_Decl_Assert, con_Decl_Transparent, con_Decl_SubType, con_Decl_DataType, con_Decl_NameType, con_Decl_Channel, con_Decl_Print]
instance Data (Decl ) where
    toConstr (PatBind _ _) = con_Decl_PatBind
    toConstr (FunBind _ _) = con_Decl_FunBind
    toConstr (Assert _) = con_Decl_Assert
    toConstr (Transparent _) = con_Decl_Transparent
    toConstr (SubType _ _) = con_Decl_SubType
    toConstr (DataType _ _) = con_Decl_DataType
    toConstr (NameType _ _) = con_Decl_NameType
    toConstr (Channel _ _) = con_Decl_Channel
    toConstr (Print _) = con_Decl_Print
    dataTypeOf _ = ty_Decl
    gunfold k z c = case constrIndex c of
                         1 -> k (k (z PatBind))
                         2 -> k (k (z FunBind))
                         3 -> k (z Assert)
                         4 -> k (z Transparent)
                         5 -> k (k (z SubType))
                         6 -> k (k (z DataType))
                         7 -> k (k (z NameType))
                         8 -> k (k (z Channel))
                         9 -> k (z Print)
                         _ -> error "gunfold(Decl)"
    gfoldl f z x = case x of
                         (PatBind a1 a2) -> ((z PatBind) `f` a1) `f` a2
                         (FunBind a1 a2) -> ((z FunBind) `f` a1) `f` a2
                         (Assert a1) -> (z Assert) `f` a1
                         (Transparent a1) -> (z Transparent) `f` a1
                         (SubType a1 a2) -> ((z SubType) `f` a1) `f` a2
                         (DataType a1 a2) -> ((z DataType) `f` a1) `f` a2
                         (NameType a1 a2) -> ((z NameType) `f` a1) `f` a2
                         (Channel a1 a2) -> ((z Channel) `f` a1) `f` a2
                         (Print a1) -> (z Print) `f` a1

tc_FunCase :: TyCon
tc_FunCase = mkTyCon3 "Language.CSPM" "AST" "FunCase"
instance Typeable (FunCase ) where
    typeOf _ = mkTyConApp tc_FunCase []
con_FunCase_FunCase :: Constr
con_FunCase_FunCase = mkConstr ty_FunCase "con_FunCase_FunCase" [] Prefix
con_FunCase_FunCaseI :: Constr
con_FunCase_FunCaseI = mkConstr ty_FunCase "con_FunCase_FunCaseI" [] Prefix
ty_FunCase :: DataType
ty_FunCase = mkDataType "Language.CSPM.AST.FunCase" [con_FunCase_FunCase, con_FunCase_FunCaseI]
instance Data (FunCase ) where
    toConstr (FunCase _ _) = con_FunCase_FunCase
    toConstr (FunCaseI _ _) = con_FunCase_FunCaseI
    dataTypeOf _ = ty_FunCase
    gunfold k z c = case constrIndex c of
                         1 -> k (k (z FunCase))
                         2 -> k (k (z FunCaseI))
                         _ -> error "gunfold(FunCase)"
    gfoldl f z x = case x of
                         (FunCase a1 a2) -> ((z FunCase) `f` a1) `f` a2
                         (FunCaseI a1 a2) -> ((z FunCaseI) `f` a1) `f` a2

tc_TypeDef :: TyCon
tc_TypeDef = mkTyCon3 "Language.CSPM" "AST" "TypeDef"
instance Typeable (TypeDef ) where
    typeOf _ = mkTyConApp tc_TypeDef []
con_TypeDef_TypeDot :: Constr
con_TypeDef_TypeDot = mkConstr ty_TypeDef "con_TypeDef_TypeDot" [] Prefix
ty_TypeDef :: DataType
ty_TypeDef = mkDataType "Language.CSPM.AST.TypeDef" [con_TypeDef_TypeDot]
instance Data (TypeDef ) where
    toConstr (TypeDot _) = con_TypeDef_TypeDot
    dataTypeOf _ = ty_TypeDef
    gunfold k z c = case constrIndex c of
                         1 -> k (z TypeDot)
                         _ -> error "gunfold(TypeDef)"
    gfoldl f z x = case x of
                         (TypeDot a1) -> (z TypeDot) `f` a1

tc_NATuples :: TyCon
tc_NATuples = mkTyCon3 "Language.CSPM" "AST" "NATuples"
instance Typeable (NATuples ) where
    typeOf _ = mkTyConApp tc_NATuples []
con_NATuples_TypeTuple :: Constr
con_NATuples_TypeTuple = mkConstr ty_NATuples "con_NATuples_TypeTuple" [] Prefix
con_NATuples_SingleValue :: Constr
con_NATuples_SingleValue = mkConstr ty_NATuples "con_NATuples_SingleValue" [] Prefix
ty_NATuples :: DataType
ty_NATuples = mkDataType "Language.CSPM.AST.NATuples" [con_NATuples_TypeTuple, con_NATuples_SingleValue]
instance Data (NATuples ) where
    toConstr (TypeTuple _) = con_NATuples_TypeTuple
    toConstr (SingleValue _) = con_NATuples_SingleValue
    dataTypeOf _ = ty_NATuples
    gunfold k z c = case constrIndex c of
                         1 -> k (z TypeTuple)
                         2 -> k (z SingleValue)
                         _ -> error "gunfold(NATuples)"
    gfoldl f z x = case x of
                         (TypeTuple a1) -> (z TypeTuple) `f` a1
                         (SingleValue a1) -> (z SingleValue) `f` a1

tc_Constructor :: TyCon
tc_Constructor = mkTyCon3 "Language.CSPM" "AST" "Constructor"
instance Typeable (Constructor ) where
    typeOf _ = mkTyConApp tc_Constructor []
con_Constructor_Constructor :: Constr
con_Constructor_Constructor = mkConstr ty_Constructor "con_Constructor_Constructor" [] Prefix
ty_Constructor :: DataType
ty_Constructor = mkDataType "Language.CSPM.AST.Constructor" [con_Constructor_Constructor]
instance Data (Constructor ) where
    toConstr (Constructor _ _) = con_Constructor_Constructor
    dataTypeOf _ = ty_Constructor
    gunfold k z c = case constrIndex c of
                         1 -> k (k (z Constructor))
                         _ -> error "gunfold(Constructor)"
    gfoldl f z x = case x of
                         (Constructor a1 a2) -> ((z Constructor) `f` a1) `f` a2

tc_AssertDecl :: TyCon
tc_AssertDecl = mkTyCon3 "Language.CSPM" "AST" "AssertDecl"
instance Typeable (AssertDecl ) where
    typeOf _ = mkTyConApp tc_AssertDecl []
con_AssertDecl_AssertBool :: Constr
con_AssertDecl_AssertBool = mkConstr ty_AssertDecl "con_AssertDecl_AssertBool" [] Prefix
con_AssertDecl_AssertRefine :: Constr
con_AssertDecl_AssertRefine = mkConstr ty_AssertDecl "con_AssertDecl_AssertRefine" [] Prefix
con_AssertDecl_AssertLTLCTL :: Constr
con_AssertDecl_AssertLTLCTL = mkConstr ty_AssertDecl "con_AssertDecl_AssertLTLCTL" [] Prefix
con_AssertDecl_AssertTauPrio :: Constr
con_AssertDecl_AssertTauPrio = mkConstr ty_AssertDecl "con_AssertDecl_AssertTauPrio" [] Prefix
con_AssertDecl_AssertModelCheck :: Constr
con_AssertDecl_AssertModelCheck = mkConstr ty_AssertDecl "con_AssertDecl_AssertModelCheck" [] Prefix
ty_AssertDecl :: DataType
ty_AssertDecl = mkDataType "Language.CSPM.AST.AssertDecl" [con_AssertDecl_AssertBool, con_AssertDecl_AssertRefine, con_AssertDecl_AssertLTLCTL, con_AssertDecl_AssertTauPrio, con_AssertDecl_AssertModelCheck]
instance Data (AssertDecl ) where
    toConstr (AssertBool _) = con_AssertDecl_AssertBool
    toConstr (AssertRefine _ _ _ _) = con_AssertDecl_AssertRefine
    toConstr (AssertLTLCTL _ _ _ _) = con_AssertDecl_AssertLTLCTL
    toConstr (AssertTauPrio _ _ _ _ _) = con_AssertDecl_AssertTauPrio
    toConstr (AssertModelCheck _ _ _ _) = con_AssertDecl_AssertModelCheck
    dataTypeOf _ = ty_AssertDecl
    gunfold k z c = case constrIndex c of
                         1 -> k (z AssertBool)
                         2 -> k (k (k (k (z AssertRefine))))
                         3 -> k (k (k (k (z AssertLTLCTL))))
                         4 -> k (k (k (k (k (z AssertTauPrio)))))
                         5 -> k (k (k (k (z AssertModelCheck))))
                         _ -> error "gunfold(AssertDecl)"
    gfoldl f z x = case x of
                         (AssertBool a1) -> (z AssertBool) `f` a1
                         (AssertRefine a1 a2 a3 a4) -> ((((z AssertRefine) `f` a1) `f` a2) `f` a3) `f` a4
                         (AssertLTLCTL a1 a2 a3 a4) -> ((((z AssertLTLCTL) `f` a1) `f` a2) `f` a3) `f` a4
                         (AssertTauPrio a1 a2 a3 a4 a5) -> (((((z AssertTauPrio) `f` a1) `f` a2) `f` a3) `f` a4) `f` a5
                         (AssertModelCheck a1 a2 a3 a4) -> ((((z AssertModelCheck) `f` a1) `f` a2) `f` a3) `f` a4

tc_FDRModels :: TyCon
tc_FDRModels = mkTyCon3 "Language.CSPM" "AST" "FDRModels"
instance Typeable (FDRModels ) where
    typeOf _ = mkTyConApp tc_FDRModels []
con_FDRModels_DeadlockFree :: Constr
con_FDRModels_DeadlockFree = mkConstr ty_FDRModels "con_FDRModels_DeadlockFree" [] Prefix
con_FDRModels_Deterministic :: Constr
con_FDRModels_Deterministic = mkConstr ty_FDRModels "con_FDRModels_Deterministic" [] Prefix
con_FDRModels_LivelockFree :: Constr
con_FDRModels_LivelockFree = mkConstr ty_FDRModels "con_FDRModels_LivelockFree" [] Prefix
ty_FDRModels :: DataType
ty_FDRModels = mkDataType "Language.CSPM.AST.FDRModels" [con_FDRModels_DeadlockFree, con_FDRModels_Deterministic, con_FDRModels_LivelockFree]
instance Data (FDRModels ) where
    toConstr (DeadlockFree) = con_FDRModels_DeadlockFree
    toConstr (Deterministic) = con_FDRModels_Deterministic
    toConstr (LivelockFree) = con_FDRModels_LivelockFree
    dataTypeOf _ = ty_FDRModels
    gunfold k z c = case constrIndex c of
                         1 -> z DeadlockFree
                         2 -> z Deterministic
                         3 -> z LivelockFree
                         _ -> error "gunfold(FDRModels)"
    gfoldl f z x = case x of
                         (DeadlockFree) -> z DeadlockFree
                         (Deterministic) -> z Deterministic
                         (LivelockFree) -> z LivelockFree

tc_FdrExt :: TyCon
tc_FdrExt = mkTyCon3 "Language.CSPM" "AST" "FdrExt"
instance Typeable (FdrExt ) where
    typeOf _ = mkTyConApp tc_FdrExt []
con_FdrExt_F :: Constr
con_FdrExt_F = mkConstr ty_FdrExt "con_FdrExt_F" [] Prefix
con_FdrExt_FD :: Constr
con_FdrExt_FD = mkConstr ty_FdrExt "con_FdrExt_FD" [] Prefix
con_FdrExt_T :: Constr
con_FdrExt_T = mkConstr ty_FdrExt "con_FdrExt_T" [] Prefix
ty_FdrExt :: DataType
ty_FdrExt = mkDataType "Language.CSPM.AST.FdrExt" [con_FdrExt_F, con_FdrExt_FD, con_FdrExt_T]
instance Data (FdrExt ) where
    toConstr (F) = con_FdrExt_F
    toConstr (FD) = con_FdrExt_FD
    toConstr (T) = con_FdrExt_T
    dataTypeOf _ = ty_FdrExt
    gunfold k z c = case constrIndex c of
                         1 -> z F
                         2 -> z FD
                         3 -> z T
                         _ -> error "gunfold(FdrExt)"
    gfoldl f z x = case x of
                         (F) -> z F
                         (FD) -> z FD
                         (T) -> z T

tc_TauRefineOp :: TyCon
tc_TauRefineOp = mkTyCon3 "Language.CSPM" "AST" "TauRefineOp"
instance Typeable (TauRefineOp ) where
    typeOf _ = mkTyConApp tc_TauRefineOp []
con_TauRefineOp_TauTrace :: Constr
con_TauRefineOp_TauTrace = mkConstr ty_TauRefineOp "con_TauRefineOp_TauTrace" [] Prefix
con_TauRefineOp_TauRefine :: Constr
con_TauRefineOp_TauRefine = mkConstr ty_TauRefineOp "con_TauRefineOp_TauRefine" [] Prefix
ty_TauRefineOp :: DataType
ty_TauRefineOp = mkDataType "Language.CSPM.AST.TauRefineOp" [con_TauRefineOp_TauTrace, con_TauRefineOp_TauRefine]
instance Data (TauRefineOp ) where
    toConstr (TauTrace) = con_TauRefineOp_TauTrace
    toConstr (TauRefine) = con_TauRefineOp_TauRefine
    dataTypeOf _ = ty_TauRefineOp
    gunfold k z c = case constrIndex c of
                         1 -> z TauTrace
                         2 -> z TauRefine
                         _ -> error "gunfold(TauRefineOp)"
    gfoldl f z x = case x of
                         (TauTrace) -> z TauTrace
                         (TauRefine) -> z TauRefine

tc_RefineOp :: TyCon
tc_RefineOp = mkTyCon3 "Language.CSPM" "AST" "RefineOp"
instance Typeable (RefineOp ) where
    typeOf _ = mkTyConApp tc_RefineOp []
con_RefineOp_Trace :: Constr
con_RefineOp_Trace = mkConstr ty_RefineOp "con_RefineOp_Trace" [] Prefix
con_RefineOp_Failure :: Constr
con_RefineOp_Failure = mkConstr ty_RefineOp "con_RefineOp_Failure" [] Prefix
con_RefineOp_FailureDivergence :: Constr
con_RefineOp_FailureDivergence = mkConstr ty_RefineOp "con_RefineOp_FailureDivergence" [] Prefix
con_RefineOp_RefusalTesting :: Constr
con_RefineOp_RefusalTesting = mkConstr ty_RefineOp "con_RefineOp_RefusalTesting" [] Prefix
con_RefineOp_RefusalTestingDiv :: Constr
con_RefineOp_RefusalTestingDiv = mkConstr ty_RefineOp "con_RefineOp_RefusalTestingDiv" [] Prefix
con_RefineOp_RevivalTesting :: Constr
con_RefineOp_RevivalTesting = mkConstr ty_RefineOp "con_RefineOp_RevivalTesting" [] Prefix
con_RefineOp_RevivalTestingDiv :: Constr
con_RefineOp_RevivalTestingDiv = mkConstr ty_RefineOp "con_RefineOp_RevivalTestingDiv" [] Prefix
con_RefineOp_TauPriorityOp :: Constr
con_RefineOp_TauPriorityOp = mkConstr ty_RefineOp "con_RefineOp_TauPriorityOp" [] Prefix
ty_RefineOp :: DataType
ty_RefineOp = mkDataType "Language.CSPM.AST.RefineOp" [con_RefineOp_Trace, con_RefineOp_Failure, con_RefineOp_FailureDivergence, con_RefineOp_RefusalTesting, con_RefineOp_RefusalTestingDiv, con_RefineOp_RevivalTesting, con_RefineOp_RevivalTestingDiv, con_RefineOp_TauPriorityOp]
instance Data (RefineOp ) where
    toConstr (Trace) = con_RefineOp_Trace
    toConstr (Failure) = con_RefineOp_Failure
    toConstr (FailureDivergence) = con_RefineOp_FailureDivergence
    toConstr (RefusalTesting) = con_RefineOp_RefusalTesting
    toConstr (RefusalTestingDiv) = con_RefineOp_RefusalTestingDiv
    toConstr (RevivalTesting) = con_RefineOp_RevivalTesting
    toConstr (RevivalTestingDiv) = con_RefineOp_RevivalTestingDiv
    toConstr (TauPriorityOp) = con_RefineOp_TauPriorityOp
    dataTypeOf _ = ty_RefineOp
    gunfold k z c = case constrIndex c of
                         1 -> z Trace
                         2 -> z Failure
                         3 -> z FailureDivergence
                         4 -> z RefusalTesting
                         5 -> z RefusalTestingDiv
                         6 -> z RevivalTesting
                         7 -> z RevivalTestingDiv
                         8 -> z TauPriorityOp
                         _ -> error "gunfold(RefineOp)"
    gfoldl f z x = case x of
                         (Trace) -> z Trace
                         (Failure) -> z Failure
                         (FailureDivergence) -> z FailureDivergence
                         (RefusalTesting) -> z RefusalTesting
                         (RefusalTestingDiv) -> z RefusalTestingDiv
                         (RevivalTesting) -> z RevivalTesting
                         (RevivalTestingDiv) -> z RevivalTestingDiv
                         (TauPriorityOp) -> z TauPriorityOp

tc_FormulaType :: TyCon
tc_FormulaType = mkTyCon3 "Language.CSPM" "AST" "FormulaType"
instance Typeable (FormulaType ) where
    typeOf _ = mkTyConApp tc_FormulaType []
con_FormulaType_LTL :: Constr
con_FormulaType_LTL = mkConstr ty_FormulaType "con_FormulaType_LTL" [] Prefix
con_FormulaType_CTL :: Constr
con_FormulaType_CTL = mkConstr ty_FormulaType "con_FormulaType_CTL" [] Prefix
ty_FormulaType :: DataType
ty_FormulaType = mkDataType "Language.CSPM.AST.FormulaType" [con_FormulaType_LTL, con_FormulaType_CTL]
instance Data (FormulaType ) where
    toConstr (LTL) = con_FormulaType_LTL
    toConstr (CTL) = con_FormulaType_CTL
    dataTypeOf _ = ty_FormulaType
    gunfold k z c = case constrIndex c of
                         1 -> z LTL
                         2 -> z CTL
                         _ -> error "gunfold(FormulaType)"
    gfoldl f z x = case x of
                         (LTL) -> z LTL
                         (CTL) -> z CTL

tc_Const :: TyCon
tc_Const = mkTyCon3 "Language.CSPM" "AST" "Const"
instance Typeable (Const ) where
    typeOf _ = mkTyConApp tc_Const []
con_Const_F_true :: Constr
con_Const_F_true = mkConstr ty_Const "con_Const_F_true" [] Prefix
con_Const_F_false :: Constr
con_Const_F_false = mkConstr ty_Const "con_Const_F_false" [] Prefix
con_Const_F_not :: Constr
con_Const_F_not = mkConstr ty_Const "con_Const_F_not" [] Prefix
con_Const_F_and :: Constr
con_Const_F_and = mkConstr ty_Const "con_Const_F_and" [] Prefix
con_Const_F_or :: Constr
con_Const_F_or = mkConstr ty_Const "con_Const_F_or" [] Prefix
con_Const_F_STOP :: Constr
con_Const_F_STOP = mkConstr ty_Const "con_Const_F_STOP" [] Prefix
con_Const_F_SKIP :: Constr
con_Const_F_SKIP = mkConstr ty_Const "con_Const_F_SKIP" [] Prefix
con_Const_F_Events :: Constr
con_Const_F_Events = mkConstr ty_Const "con_Const_F_Events" [] Prefix
con_Const_F_Int :: Constr
con_Const_F_Int = mkConstr ty_Const "con_Const_F_Int" [] Prefix
con_Const_F_Bool :: Constr
con_Const_F_Bool = mkConstr ty_Const "con_Const_F_Bool" [] Prefix
con_Const_F_CHAOS :: Constr
con_Const_F_CHAOS = mkConstr ty_Const "con_Const_F_CHAOS" [] Prefix
con_Const_F_Concat :: Constr
con_Const_F_Concat = mkConstr ty_Const "con_Const_F_Concat" [] Prefix
con_Const_F_Len2 :: Constr
con_Const_F_Len2 = mkConstr ty_Const "con_Const_F_Len2" [] Prefix
con_Const_F_Mult :: Constr
con_Const_F_Mult = mkConstr ty_Const "con_Const_F_Mult" [] Prefix
con_Const_F_Div :: Constr
con_Const_F_Div = mkConstr ty_Const "con_Const_F_Div" [] Prefix
con_Const_F_Mod :: Constr
con_Const_F_Mod = mkConstr ty_Const "con_Const_F_Mod" [] Prefix
con_Const_F_Add :: Constr
con_Const_F_Add = mkConstr ty_Const "con_Const_F_Add" [] Prefix
con_Const_F_Sub :: Constr
con_Const_F_Sub = mkConstr ty_Const "con_Const_F_Sub" [] Prefix
con_Const_F_Eq :: Constr
con_Const_F_Eq = mkConstr ty_Const "con_Const_F_Eq" [] Prefix
con_Const_F_NEq :: Constr
con_Const_F_NEq = mkConstr ty_Const "con_Const_F_NEq" [] Prefix
con_Const_F_GE :: Constr
con_Const_F_GE = mkConstr ty_Const "con_Const_F_GE" [] Prefix
con_Const_F_LE :: Constr
con_Const_F_LE = mkConstr ty_Const "con_Const_F_LE" [] Prefix
con_Const_F_LT :: Constr
con_Const_F_LT = mkConstr ty_Const "con_Const_F_LT" [] Prefix
con_Const_F_GT :: Constr
con_Const_F_GT = mkConstr ty_Const "con_Const_F_GT" [] Prefix
con_Const_F_Guard :: Constr
con_Const_F_Guard = mkConstr ty_Const "con_Const_F_Guard" [] Prefix
con_Const_F_Sequential :: Constr
con_Const_F_Sequential = mkConstr ty_Const "con_Const_F_Sequential" [] Prefix
con_Const_F_Interrupt :: Constr
con_Const_F_Interrupt = mkConstr ty_Const "con_Const_F_Interrupt" [] Prefix
con_Const_F_ExtChoice :: Constr
con_Const_F_ExtChoice = mkConstr ty_Const "con_Const_F_ExtChoice" [] Prefix
con_Const_F_IntChoice :: Constr
con_Const_F_IntChoice = mkConstr ty_Const "con_Const_F_IntChoice" [] Prefix
con_Const_F_Hiding :: Constr
con_Const_F_Hiding = mkConstr ty_Const "con_Const_F_Hiding" [] Prefix
con_Const_F_Timeout :: Constr
con_Const_F_Timeout = mkConstr ty_Const "con_Const_F_Timeout" [] Prefix
con_Const_F_Interleave :: Constr
con_Const_F_Interleave = mkConstr ty_Const "con_Const_F_Interleave" [] Prefix
ty_Const :: DataType
ty_Const = mkDataType "Language.CSPM.AST.Const" [con_Const_F_true, con_Const_F_false, con_Const_F_not, con_Const_F_and, con_Const_F_or, con_Const_F_STOP, con_Const_F_SKIP, con_Const_F_Events, con_Const_F_Int, con_Const_F_Bool, con_Const_F_CHAOS, con_Const_F_Concat, con_Const_F_Len2, con_Const_F_Mult, con_Const_F_Div, con_Const_F_Mod, con_Const_F_Add, con_Const_F_Sub, con_Const_F_Eq, con_Const_F_NEq, con_Const_F_GE, con_Const_F_LE, con_Const_F_LT, con_Const_F_GT, con_Const_F_Guard, con_Const_F_Sequential, con_Const_F_Interrupt, con_Const_F_ExtChoice, con_Const_F_IntChoice, con_Const_F_Hiding, con_Const_F_Timeout, con_Const_F_Interleave]
instance Data (Const ) where
    toConstr (F_true) = con_Const_F_true
    toConstr (F_false) = con_Const_F_false
    toConstr (F_not) = con_Const_F_not
    toConstr (F_and) = con_Const_F_and
    toConstr (F_or) = con_Const_F_or
    toConstr (F_STOP) = con_Const_F_STOP
    toConstr (F_SKIP) = con_Const_F_SKIP
    toConstr (F_Events) = con_Const_F_Events
    toConstr (F_Int) = con_Const_F_Int
    toConstr (F_Bool) = con_Const_F_Bool
    toConstr (F_CHAOS) = con_Const_F_CHAOS
    toConstr (F_Concat) = con_Const_F_Concat
    toConstr (F_Len2) = con_Const_F_Len2
    toConstr (F_Mult) = con_Const_F_Mult
    toConstr (F_Div) = con_Const_F_Div
    toConstr (F_Mod) = con_Const_F_Mod
    toConstr (F_Add) = con_Const_F_Add
    toConstr (F_Sub) = con_Const_F_Sub
    toConstr (F_Eq) = con_Const_F_Eq
    toConstr (F_NEq) = con_Const_F_NEq
    toConstr (F_GE) = con_Const_F_GE
    toConstr (F_LE) = con_Const_F_LE
    toConstr (F_LT) = con_Const_F_LT
    toConstr (F_GT) = con_Const_F_GT
    toConstr (F_Guard) = con_Const_F_Guard
    toConstr (F_Sequential) = con_Const_F_Sequential
    toConstr (F_Interrupt) = con_Const_F_Interrupt
    toConstr (F_ExtChoice) = con_Const_F_ExtChoice
    toConstr (F_IntChoice) = con_Const_F_IntChoice
    toConstr (F_Hiding) = con_Const_F_Hiding
    toConstr (F_Timeout) = con_Const_F_Timeout
    toConstr (F_Interleave) = con_Const_F_Interleave
    dataTypeOf _ = ty_Const
    gunfold k z c = case constrIndex c of
                         1 -> z F_true
                         2 -> z F_false
                         3 -> z F_not
                         4 -> z F_and
                         5 -> z F_or
                         6 -> z F_STOP
                         7 -> z F_SKIP
                         8 -> z F_Events
                         9 -> z F_Int
                         10 -> z F_Bool
                         11 -> z F_CHAOS
                         12 -> z F_Concat
                         13 -> z F_Len2
                         14 -> z F_Mult
                         15 -> z F_Div
                         16 -> z F_Mod
                         17 -> z F_Add
                         18 -> z F_Sub
                         19 -> z F_Eq
                         20 -> z F_NEq
                         21 -> z F_GE
                         22 -> z F_LE
                         23 -> z F_LT
                         24 -> z F_GT
                         25 -> z F_Guard
                         26 -> z F_Sequential
                         27 -> z F_Interrupt
                         28 -> z F_ExtChoice
                         29 -> z F_IntChoice
                         30 -> z F_Hiding
                         31 -> z F_Timeout
                         32 -> z F_Interleave
                         _ -> error "gunfold(Const)"
    gfoldl f z x = case x of
                         (F_true) -> z F_true
                         (F_false) -> z F_false
                         (F_not) -> z F_not
                         (F_and) -> z F_and
                         (F_or) -> z F_or
                         (F_STOP) -> z F_STOP
                         (F_SKIP) -> z F_SKIP
                         (F_Events) -> z F_Events
                         (F_Int) -> z F_Int
                         (F_Bool) -> z F_Bool
                         (F_CHAOS) -> z F_CHAOS
                         (F_Concat) -> z F_Concat
                         (F_Len2) -> z F_Len2
                         (F_Mult) -> z F_Mult
                         (F_Div) -> z F_Div
                         (F_Mod) -> z F_Mod
                         (F_Add) -> z F_Add
                         (F_Sub) -> z F_Sub
                         (F_Eq) -> z F_Eq
                         (F_NEq) -> z F_NEq
                         (F_GE) -> z F_GE
                         (F_LE) -> z F_LE
                         (F_LT) -> z F_LT
                         (F_GT) -> z F_GT
                         (F_Guard) -> z F_Guard
                         (F_Sequential) -> z F_Sequential
                         (F_Interrupt) -> z F_Interrupt
                         (F_ExtChoice) -> z F_ExtChoice
                         (F_IntChoice) -> z F_IntChoice
                         (F_Hiding) -> z F_Hiding
                         (F_Timeout) -> z F_Timeout
                         (F_Interleave) -> z F_Interleave

tc_Comment :: TyCon
tc_Comment = mkTyCon3 "Language.CSPM" "AST" "Comment"
instance Typeable (Comment ) where
    typeOf _ = mkTyConApp tc_Comment []
con_Comment_LineComment :: Constr
con_Comment_LineComment = mkConstr ty_Comment "con_Comment_LineComment" [] Prefix
con_Comment_BlockComment :: Constr
con_Comment_BlockComment = mkConstr ty_Comment "con_Comment_BlockComment" [] Prefix
con_Comment_PragmaComment :: Constr
con_Comment_PragmaComment = mkConstr ty_Comment "con_Comment_PragmaComment" [] Prefix
ty_Comment :: DataType
ty_Comment = mkDataType "Language.CSPM.AST.Comment" [con_Comment_LineComment, con_Comment_BlockComment, con_Comment_PragmaComment]
instance Data (Comment ) where
    toConstr (LineComment _) = con_Comment_LineComment
    toConstr (BlockComment _) = con_Comment_BlockComment
    toConstr (PragmaComment _) = con_Comment_PragmaComment
    dataTypeOf _ = ty_Comment
    gunfold k z c = case constrIndex c of
                         1 -> k (z LineComment)
                         2 -> k (z BlockComment)
                         3 -> k (z PragmaComment)
                         _ -> error "gunfold(Comment)"
    gfoldl f z x = case x of
                         (LineComment a1) -> (z LineComment) `f` a1
                         (BlockComment a1) -> (z BlockComment) `f` a1
                         (PragmaComment a1) -> (z PragmaComment) `f` a1
