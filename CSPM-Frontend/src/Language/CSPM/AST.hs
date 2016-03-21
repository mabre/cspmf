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

{-# LANGUAGE DeriveDataTypeable #-}
--DeriveGeneric
-- {-# LANGUAGE EmptyDataDecls, RankNTypes #-}
-- {-# LANGUAGE RecordWildCards #-}
--GeneralizedNewtypeDeriving
module Language.CSPM.AST
where

import Token
import SrcLoc --(SrcLoc(..))

-- import Data.Typeable (Typeable) -- TODO Typeable
-- import Data.Generics.Basics (Data)
-- import GHC.Generics (Generic)
import Data.IntMap (IntMap)
import Data.Map (Map)
import Data.Array.IArray

type AstAnnotation x = IntMap x
type Bindings = Map String UniqueIdent
type FreeNames = IntMap UniqueIdent

data NodeId = NodeId {unNodeId :: Int}
derive Eq NodeId
derive Ord NodeId
derive Show NodeId
derive Ix NodeId
succ' :: NodeId -> NodeId
succ' (NodeId i) = NodeId $ succ i

mkNodeId :: Int -> NodeId
mkNodeId = NodeId

data Labeled t = Labeled {
    nodeId :: NodeId
   ,srcLoc  :: SrcLoc
   ,unLabel :: t
}
derive Eq Labeled
derive Ord Labeled
derive Show Labeled

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
identId = uniqueIdentId . unUIdent . unLabel

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

data IDType 
  = VarID | ChannelID | NameTypeID | FunID
  | ConstrID | DataTypeID | TransparentID
  | BuiltInID
derive Eq IDType
derive Ord IDType
derive Show IDType

data PrologMode = PrologGround | PrologVariable
derive Eq PrologMode
derive Ord PrologMode
derive Show PrologMode

{- Actually BindType and PrologMode are semantically aquivalent -}
data BindType = LetBound | NotLetBound
derive Eq BindType
derive Ord BindType
derive Show BindType

isLetBound :: BindType -> Bool
isLetBound x = x==LetBound

data Module a = Module {
   moduleDecls :: [LDecl]
  ,moduleTokens :: Maybe [Token]
  ,moduleSrcLoc :: SrcLoc
  ,moduleComments :: [LocComment]
  ,modulePragmas :: [Pragma]
}
derive Eq Module
derive Ord Module
derive Show Module

data FromParser = FromParser
-- derive Typeable FromParser -- TODO Typeable
-- instance Data FromParser
instance Eq FromParser

castModule :: Module a -> Module b
castModule (Module mds mts msrcloc mcs mps) = Module mds mts msrcloc mcs mps

type ModuleFromParser = Module FromParser

type LExp = Labeled Exp
type LProc = LExp --LProc is just a typealias for better readablility

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
-- derive Typeable Exp -- TODO Typeable

type LRange = Labeled Range
data Range
  = RangeEnum [LExp]
  | RangeClosed LExp LExp
  | RangeOpen LExp
derive Eq Range
derive Ord Range
derive Show Range

type LCommField = Labeled CommField
data CommField
  =  InComm LPattern
  | InCommGuarded LPattern LExp
  | OutComm LExp
derive Eq CommField
derive Ord CommField
derive Show CommField

type LLinkList = Labeled LinkList
data LinkList
  = LinkList [LLink]
  | LinkListComprehension [LCompGen] [LLink]
derive Eq LinkList
derive Ord LinkList
derive Show LinkList

type LLink = Labeled Link
data Link = Link LExp LExp deriving (Eq, Ord, Show)

type LRename = Labeled Rename
data Rename = Rename LExp LExp deriving (Eq, Ord, Show)

type LBuiltIn = Labeled BuiltIn
data BuiltIn = BuiltIn Const deriving (Eq, Ord, Show)

lBuiltInToConst :: LBuiltIn -> Const
lBuiltInToConst = h . unLabel where
  h (BuiltIn c) = c

type LCompGenList = Labeled [LCompGen]
type LCompGen = Labeled CompGen
data CompGen
  = Generator LPattern LExp
  | Guard LExp
derive Eq CompGen
derive Ord CompGen
derive Show CompGen

type LPattern = Labeled Pattern
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
data TypeDef
  = TypeDot [LNATuples] -- a.(b,c).d.(e,f,g)
derive Eq TypeDef
derive Ord TypeDef
derive Show TypeDef

type LNATuples = Labeled NATuples
data NATuples
  = TypeTuple [LExp]
  | SingleValue LExp
derive Eq NATuples
derive Ord NATuples
derive Show NATuples

type LConstructor = Labeled Constructor
data Constructor
  = Constructor LIdent (Maybe LTypeDef) 
derive Eq Constructor
derive Ord Constructor
derive Show Constructor

withLabel :: ( NodeId -> a -> b ) -> Labeled a -> Labeled b
withLabel f x = x.{unLabel = f (nodeId x) (unLabel x) }

type LAssertDecl = Labeled AssertDecl
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
data FDRModels
  = DeadlockFree
  | Deterministic
  | LivelockFree
derive Eq FDRModels
derive Ord FDRModels
derive Show FDRModels

type LFdrExt = Labeled FdrExt
data FdrExt 
  = F 
  | FD
  | T
derive Eq FdrExt
derive Ord FdrExt
derive Show FdrExt

type LTauRefineOp = Labeled TauRefineOp 
data TauRefineOp
  = TauTrace
  | TauRefine
derive Eq TauRefineOp
derive Ord TauRefineOp
derive Show TauRefineOp

type LRefineOp = Labeled RefineOp
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
data FormulaType
  = LTL
  | CTL
derive Eq FormulaType
derive Ord FormulaType
derive Show FormulaType

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
data Comment
  = LineComment String
  | BlockComment String
  | PragmaComment Pragma
derive Eq Comment
derive Ord Comment
derive Show Comment
