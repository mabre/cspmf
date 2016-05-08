-----------------------------------------------------------------------------
-- |
-- Module      :  Language.CSPM.Rename
-- Copyright   :  (c) Fontaine 2008 - 2011
-- License     :  BSD3
-- 
-- Maintainer  :  Fontaine@cs.uni-duesseldorf.de
-- Stability   :  experimental
-- Portability :  GHC-only
--
-- Compute the mapping between the using occurences and the defining occurences of all Identifier in a Module
-- Also decide whether to use ground or non-ground- representaions for the translation to Prolog.

-- {-# LANGUAGE DeriveDataTypeable #-}
-- {-# LANGUAGE RecordWildCards #-}
-- EmptyDataDecls
-- ViewPatterns

module Language.CSPM.Rename
--   (
--    renameModule
--   ,RenameError (..)
--   ,RenameInfo (..)
--   ,ModuleFromRenaming
--   ,FromRenaming
--   )
where

import Language.CSPM.AST
import Language.CSPM.AST as AST()
import Language.CSPM.SrcLoc as SrcLoc()
import Language.CSPM.BuiltIn as BuiltIn

import Data.Data hiding (DataType)
import Data.Generics.Schemes (everywhere)
import Data.Generics.Aliases (mkT)
import Data.Typeable
-- import Control.Exception (Exception)

-- import Control.Monad.Error
import frege.control.monad.MState
import Data.Set (Set)
import Data.Map as Map()
import Data.Map (Map)
import Data.Set as Set()
-- import Data.IntMap as IntMap()
import Data.List as List()
import Data.Maybe
import frege.data.IntMap


instance Data FromRenaming
  where
    gunfold = error "instance Data FromRenaming gunfold"
    toConstr = error "instance Data FromRenaming toConstr"
    dataTypeOf _ = mkDataType "Language.CSPM.Rename.FromRenaming" []

-- | A module that has gone through renaming
type ModuleFromRenaming = Module FromRenaming

-- | Tag that a module has gone through renaming.
data FromRenaming = FromRenaming
tc_FromRenaming :: TyCon
tc_FromRenaming = mkTyCon3 "HHU" "Test1" "FromRenaming"
instance Typeable (FromRenaming ) where
    typeOf _ = mkTyConApp tc_FromRenaming []

-- | 'renameModule' renames a 'Module'.
-- | (also calls mergeFunBinds)
renameModule ::
     ModuleFromParser
  -> Either RenameError (ModuleFromRenaming, RenameInfo)
renameModule m = do
  let m' = mergeFunBinds m
  st <- execStateT (initPrelude >> rnModule m') initialRState
  return
    (
     applyRenaming m' (st.identDefinition) (st.identUse)
    ,st)

type RM x = StateT RenameInfo (Either RenameError) x

type UniqueName = Int

-- | Gather all information about an renaming. 
data RenameInfo = RenameInfo
  {
    nameSupply :: Int
   ,localBindings :: Map String UniqueIdent -- used to check that we do not bind a name twice inside a pattern
   ,visible  :: Map String UniqueIdent      -- everything that is visible
   ,identDefinition :: AstAnnotation UniqueIdent
   ,identUse  :: AstAnnotation UniqueIdent
   ,usedNames :: Set String
   ,prologMode :: PrologMode -- could use a readermonad for prologMode and bindType
   ,bindType   :: BindType
  }
-- derive Show RenameInfo

initialRState :: RenameInfo
initialRState = RenameInfo { nameSupply    = 0,
                             localBindings = Map.empty,
                             visible       = Map.empty,
                             identDefinition = IntMap.empty,
                             identUse        = IntMap.empty,
                             usedNames       = Set.empty,
                             prologMode      = PrologVariable,
                             bindType        = NotLetBound }

initPrelude :: RM ()
initPrelude
    = forM_ BuiltIn.builtIns $ \bi -> do
        bindNewTopIdent BuiltInID (labeled $ Ident bi)

data RenameError
  = RenameError {
   renameErrorMsg :: String
  ,renameErrorLoc :: SrcLoc.SrcLoc
  }
derive Show RenameError

-- instance Exception RenameError


-- instance Error RenameError where
--   noMsg = RenameError { renameErrorMsg = "no Messsage", renameErrorLoc = SrcLoc.NoLocation }
--   strMsg m = RenameError { renameErrorMsg = m, renameErrorLoc = SrcLoc.NoLocation }

throwError = undefined -- TODO Error

lookupVisible :: LIdent -> RM (Maybe UniqueIdent)
lookupVisible i = do
  vis <- gets RenameInfo.visible
  return $ Map.lookup (i.unLabel.unIdent) vis

getOrigName :: LIdent -> String
getOrigName l = l.unLabel.unIdent

bindNewTopIdent :: IDType -> LIdent -> RM ()
bindNewTopIdent t i = do
  vis <- lookupVisible i
  case vis of
    Nothing -> bindNewUniqueIdent t i
    Just _ -> throwError $ RenameError {
      renameErrorMsg = "Redefinition of toplevel name " ++ getOrigName i
     ,renameErrorLoc = i.srcLoc }

bindNewUniqueIdent :: IDType -> LIdent -> RM ()
bindNewUniqueIdent iType lIdent = do
  let origName = getOrigName lIdent
  {- check that we do not bind a variable twice i.e. in a pattern -}
  local <- gets RenameInfo.localBindings
  when (isJust $ Map.lookup origName local) $
    throwError $ RenameError {
       renameErrorMsg = "Redefinition of " ++ origName
       ,renameErrorLoc = lIdent.srcLoc }
  vis <- lookupVisible lIdent
  case vis of
   Nothing -> addNewBinding
   (Just u) -> case (iType, u.idType) of
      {- If there is a Constructor of Channel in scope and we try to bind a VarID
      this VarID is a pattern match for the existing binding -}

      (VarID, ConstrID) -> useExistingBinding u
      (VarID, ChannelID) -> useExistingBinding u

      (VarID, _) -> addNewBinding
      {- We throw an error if the csp-code tries to rebind a constructor or a channel ID -}
      (_    , ConstrID) -> throwError $ RenameError {
          renameErrorMsg = "Illigal reuse of Contructor " ++ origName
         ,renameErrorLoc = lIdent.srcLoc }
      (_    , ChannelID) -> throwError $ RenameError {
          renameErrorMsg = "Illigal reuse of Channel " ++ origName
         ,renameErrorLoc = lIdent.srcLoc }

      (_, _) -> addNewBinding
 where
    useExistingBinding :: UniqueIdent -> RM ()
    useExistingBinding ident = do
      let ptr = lIdent.nodeId.unNodeId
      StateT.modify $ \s -> s.
        { identDefinition = IntMap.insert ptr ident $ s.identDefinition }

    addNewBinding :: RM ()
    addNewBinding = do
      let origName = lIdent.unLabel.unIdent
          nodeID = lIdent.nodeId
    
      (nameNew,unique) <- nextUniqueName origName
      plMode <- gets RenameInfo.prologMode
      bType  <- gets RenameInfo.bindType
      let uIdent = UniqueIdent {
         uniqueIdentId = unique
        ,bindingSide = nodeID
        ,bindingLoc  = lIdent.srcLoc
        ,idType = iType
        ,realName = origName
        ,newName = nameNew
        ,prologMode = plMode
        ,bindType   = bType  }
      StateT.modify $ \s -> s.
        { localBindings = Map.insert origName uIdent $ s.localBindings
        , visible       = Map.insert origName uIdent $ s.visible
        , identDefinition = IntMap.insert
            (nodeID.unNodeId) uIdent $ s.identDefinition }


    nextUniqueName :: String -> RM (String,UniqueName)
    nextUniqueName oldName = do
      n <- gets RenameInfo.nameSupply
      StateT.modify $ \s -> s.{nameSupply = succ n}
      occupied <- gets RenameInfo.usedNames
      let
         suffixes = "" : map show ([2..9] ++ [n + 10 .. ])
         candidates = map ((++) oldName) suffixes
         nextName = head $ filter (\x -> not $ Set.member x occupied) candidates
      StateT.modify $ \s -> s.{usedNames = Set.insert nextName $ s.usedNames}
      return (nextName,n)

localScope :: RM x -> RM x
localScope h = do 
  vis <- gets RenameInfo.visible
  localBind <- gets RenameInfo.localBindings
  StateT.modify $ \s -> s.{localBindings = Map.empty}
  res <- h                 
  StateT.modify $ \e -> e.{
     visible = vis
    ,localBindings = localBind }
  return res

useIdent :: LIdent -> RM ()
useIdent lIdent = do
  vis <- lookupVisible lIdent
  case vis of
    Nothing -> case elem (getOrigName lIdent) builtInsRename of
                 True ->  addBuiltInBinding lIdent
                 False -> throwError $ RenameError {
                      renameErrorMsg = "Unbound Identifier :" ++ getOrigName lIdent
                     ,renameErrorLoc = lIdent.srcLoc }
    Just defIdent -> StateT.modify $ \s -> s.
         { identUse =  IntMap.insert 
             (lIdent.nodeId.unNodeId) defIdent $ s.identUse }

addBuiltInBinding :: LIdent -> RM ()
addBuiltInBinding lIdent = do
    let origName = lIdent.unLabel.unIdent
        nodeID = lIdent.nodeId
    plMode <- gets RenameInfo.prologMode
    bType  <- gets RenameInfo.bindType
    let uIdent = UniqueIdent {
                     uniqueIdentId = -1
                     ,bindingSide = nodeID
                     ,bindingLoc  = lIdent.srcLoc
                     ,idType = BuiltInID
                     ,realName = origName
                     ,newName = origName
                     ,prologMode = plMode
                     ,bindType   = bType  }
    StateT.modify $ \s -> s.
        { localBindings = Map.insert origName uIdent $ s.localBindings
                         , visible       = Map.insert origName uIdent $ s.visible
                         , identDefinition = IntMap.insert
                              (nodeID.unNodeId) uIdent $ s.identDefinition }

{-
rn just walks through the AST, without modifing it.
The actual renamings are stored in a sepearte AstAnnotation inside the RM-Monad
-}

nop :: RM ()
nop = return ()

rnModule :: ModuleFromParser -> RM ()
rnModule = rnDeclList . ModuleFromParser.moduleDecls

rnExpList :: [LExp] -> RM ()
rnExpList = mapM_ rnExp

-- rename an expression
rnExp :: LExp -> RM ()
rnExp expression = case expression.unLabel of
  Var ident -> useIdent ident
  IntExp _ -> nop
  SetExp a Nothing -> rnRange a
  SetExp a (Just comp) -> inCompGen comp (rnRange a)
  ListExp a Nothing -> rnRange a
  ListExp a (Just comp) -> inCompGen comp (rnRange a)
  ClosureComprehension (a,b) -> inCompGen b (rnExpList a)
  Let decls e -> localScope (rnDeclList decls >> rnExp e)
  Ifte a b c -> rnExp a >> rnExp b >> rnExp c
  CallFunction a args -> rnExp a >> mapM_ rnExpList args
  CallBuiltIn _ args -> mapM_ rnExpList args
  Lambda pList e -> localScope (rnPatList pList >> rnExp e)
  Stop -> nop
  Skip -> nop
  CTrue -> nop
  CFalse -> nop
  Events -> nop
  BoolSet -> nop
  IntSet -> nop
  TupleExp l -> rnExpList l
  Parens a -> rnExp a 
  AndExp a b -> rnExp a >> rnExp b
  OrExp a b -> rnExp a >> rnExp b
  NotExp a -> rnExp a
  NegExp a -> rnExp a
  Fun1 _ a -> rnExp a
  Fun2 _ a b -> rnExp a >> rnExp b
  DotTuple l -> rnExpList l
  Closure l -> rnExpList l
  ProcSharing al p1 p2 -> rnExp al >> rnExp p1 >> rnExp p2
  ProcAParallel a b c d -> rnExp a >> rnExp b >> rnExp c >> rnExp d
  ProcLinkParallel l e1 e2 -> rnLinkList l >> rnExp e1 >> rnExp e2
  ProcRenaming rlist gen proc -> case gen of
    Nothing -> mapM_ reRename rlist >> rnExp proc
    Just comp -> inCompGenL comp (mapM_ reRename rlist) >> rnExp proc
  ProcException p1 e p2 -> rnExp p1 >> rnExp e >> rnExp p2
  ProcRepSequence a p -> inCompGenL a (rnExp p)
  ProcRepInternalChoice a p -> inCompGenL a (rnExp p)
  ProcRepInterleave a p -> inCompGenL a (rnExp p)
  ProcRepExternalChoice  a p -> inCompGenL a (rnExp p)
  ProcRepAParallel comp a p -> inCompGenL comp (rnExp a >> rnExp p)
  ProcRepLinkParallel comp l p
    -> rnLinkList l >> inCompGenL comp (rnExp p)
  ProcRepSharing comp s p -> rnExp s >> inCompGenL comp (rnExp p)
  PrefixExp chan fields proc -> localScope $ do
    rnExp chan
    mapM_ rnCommField fields
    rnExp proc
{-
Catch these cases to make the match total.
These Constructors may only appear in later stages.
-}
  ExprWithFreeNames {} -> error "Rename.hs : no match for ExprWithFreeNames"
  LambdaI {} -> error "Rename.hs : no match for LambdaI"
  LetI {} -> error "Rename.hs : no match for LetI"
  PrefixI {} -> error "Rename.hs : no match for PrefixI"

rnRange :: LRange -> RM ()
rnRange r = case r.unLabel of
  RangeEnum l -> rnExpList l
  RangeOpen a -> rnExp a
  RangeClosed a b -> rnExp a >> rnExp b

rnPatList :: [LPattern] -> RM ()
rnPatList = mapM_ rnPattern

rnPattern :: LPattern -> RM ()
rnPattern p = case p.unLabel of
  IntPat _ -> nop
  TruePat -> nop
  FalsePat -> nop
  WildCard -> nop
  VarPat lIdent -> bindNewUniqueIdent VarID lIdent
  Also l -> rnPatList l
  Append l -> rnPatList l
  DotPat l -> rnPatList l
  SingleSetPat a -> rnPattern a
  EmptySetPat -> nop
  ListEnumPat l -> rnPatList l
  TuplePat l -> rnPatList l
-- ConstrPatm, Selectors and Selector are generated during renaming
  ConstrPat {} -> error "Rename.hs : no match for ConstrPat"
  Selectors {} -> error "Rename.hs : no match for Selectors"
  Selector {} -> error "Rename.hs : no match for Selector"

rnCommField :: LCommField -> RM ()
rnCommField f = case f.unLabel of
  InComm pat -> rnPattern pat
  InCommGuarded p g -> rnExp g >> rnPattern p
  OutComm e -> rnExp e

inCompGenL :: LCompGenList -> RM () -> RM ()
inCompGenL l r = inCompGen (l.unLabel) r

inCompGen :: [LCompGen] -> RM () -> RM ()
inCompGen (h:t) ret = localScope $ do
  rnCompGen h
  inCompGen t ret
inCompGen [] ret = ret 

rnCompGen :: LCompGen -> RM ()
rnCompGen g = case g.unLabel of
  Generator pat e -> rnExp e >> rnPattern pat
  Guard e -> rnExp e

reRename :: LRename -> RM ()
reRename r = case r.unLabel of
  Rename e1 e2 -> rnExp e1 >> rnExp e2

rnLinkList :: LLinkList -> RM ()
rnLinkList ll = case ll.unLabel of
  LinkList l -> mapM_ rnLink l
  LinkListComprehension a b -> inCompGen a (mapM_ rnLink b)
 where
    rnLink l = case l.unLabel of
      Link a b -> rnExp a >> rnExp b

-- rename a recursive binding group
rnDeclList :: [LDecl] -> RM ()
rnDeclList declList = do
  StateT.modify $ \s -> s.{prologMode = PrologGround ,bindType   = LetBound}
  forM_ declList declLHS
  StateT.modify $ \s -> s.{prologMode = PrologVariable ,bindType   = NotLetBound}
  forM_ declList declRHS

declLHS :: LDecl -> RM ()
declLHS d = case d.unLabel of
  PatBind pat _ -> rnPattern pat
   --todo : proper type-checking/counting number of Funargs
  FunBind i _ -> bindNewUniqueIdent FunID i 
  Assert {} -> nop
  Transparent tl -> mapM_ (bindNewTopIdent TransparentID) tl
  SubType i clist -> do
    bindNewTopIdent DataTypeID i
    mapM_ rnSubtypeLHS clist
  DataType i clist -> do
    bindNewTopIdent DataTypeID i
    mapM_ rnConstructorLHS clist
  NameType i _ -> bindNewTopIdent NameTypeID i
  Channel chList _ -> mapM_ (bindNewTopIdent ChannelID) chList
  Print _ -> nop
 where
    rnConstructorLHS :: LConstructor -> RM ()
    rnConstructorLHS c = case c.unLabel of
      Constructor c _ -> bindNewTopIdent ConstrID c

    rnSubtypeLHS :: LConstructor -> RM ()
    rnSubtypeLHS c = case c.unLabel of
      (Constructor c _) -> useIdent c


declRHS :: LDecl -> RM ()
declRHS d = case d.unLabel of
  PatBind _ e -> rnExp e
  FunBind _ cases -> mapM_ rnFunCase cases
  Assert a -> case a.unLabel of
      AssertBool e -> rnExp e
      AssertRefine _ p1 _ p2 -> rnExp p1 >> rnExp p2
      AssertLTLCTL _ p _ _ -> rnExp p
      AssertTauPrio _ p1 _ p2 e -> rnExp p1 >> rnExp p2 >> rnExp e
      AssertModelCheck _ p _ _ -> rnExp p
  Transparent _ -> nop  
  SubType  _ clist -> forM_ clist rnConstructorRHS
  DataType _ clist -> forM_ clist rnConstructorRHS
  NameType _ td -> rnTypeDef td
  Channel _ Nothing -> nop
  Channel _ (Just td) -> rnTypeDef td
  Print e -> rnExp e
 where
    rnFunCase c = case c of  --todo:uses Labeled version
      FunCase pat e -> localScope (mapM_ rnPatList pat >> rnExp e)
      FunCaseI {} -> error "Rename.hs : no match for FunCaseI"
    rnConstructorRHS :: LConstructor -> RM ()
    rnConstructorRHS = rc . LConstructor.unLabel where
      rc (Constructor _ Nothing ) = nop
      rc (Constructor _ (Just t)) = rnTypeDef t

rnTypeDef :: LTypeDef -> RM ()
rnTypeDef t = case t.unLabel of
  TypeDot na_tuples -> rnDotArgs na_tuples

rnDotArgs :: [LNATuples] -> RM ()
rnDotArgs na_tuples = mapM_ rnNATuples na_tuples
  where
    rnNATuples :: LNATuples -> RM ()
    rnNATuples na_tuple = case na_tuple.unLabel of
       SingleValue e -> rnExp e
       TypeTuple le  -> rnExpList le

{-
rnTypeDef :: LTypeDef -> RM ()
rnTypeDef t = case t.unLabel of
  TypeTuple l -> rnExpList l
  TypeDot l -> rnExpList l
-}

applyRenaming ::
     ModuleFromParser
  -> AstAnnotation UniqueIdent
  -> AstAnnotation UniqueIdent
  -> ModuleFromRenaming
applyRenaming ast defIdent usedIdent
  = castModule $ everywhere (mkT patchVarPat . mkT patchIdent) ast
  where
    patchIdent :: LIdent -> LIdent
    patchIdent l =
      let nodeID = l.nodeId.unNodeId in
      case (IntMap.lookup nodeID usedIdent, IntMap.lookup nodeID defIdent) of
        (Just use, _)  -> setNode l $ UIdent use
        (_, Just def)  -> setNode l $ UIdent def
        (Nothing, Nothing) -> error $
            "internal error: patchIdent nodeId not found:" ++ show nodeID
        (Just _ , Just _ ) -> error $
            "internal error: patchIdent nodeId is defining and using:" ++ show nodeID

    patchVarPat :: Pattern -> Pattern
    patchVarPat (p@(VarPat x)) = case UniqueIdent.idType $ unUIdent $ x.unLabel of
        VarID -> p
        _ -> ConstrPat x
    patchVarPat x = x

-- | If a function is defined via pattern matching for serveral cases,
-- | the parser returns each case as an individual declaration.
-- | mergeFunBinds merges contiguous cases of the same function into one declaration.
mergeFunBinds :: ModuleFromParser -> ModuleFromParser
mergeFunBinds = everywhere (mkT patchModule . mkT patchLet)
  where
    patchModule :: ModuleFromParser -> ModuleFromParser
    patchModule m = m.{moduleDecls = mergeDecls $ m.moduleDecls}

    patchLet :: Exp -> Exp
    patchLet (Let decls expr) = Let (mergeDecls decls) expr
    patchLet x = x

    mergeDecls :: [LDecl] -> [LDecl]
    mergeDecls = map joinGroup . List.groupBy sameFunction

    sameFunction a b = case (a.unLabel, b.unLabel) of
       (FunBind n1 _, FunBind n2 _) -> n1.unLabel == n2.unLabel
       _ -> False

    joinGroup :: [LDecl] -> LDecl
    joinGroup (l@(firstCase : _)) = case firstCase.unLabel of
      FunBind fname _ -> setNode firstCase $ FunBind fname $ map getFunCase l
      _ -> firstCase
    joinGroup [] = error "unreachable : groupBy empty group ?"

    getFunCase :: LDecl -> FunCase
    getFunCase d = case d.unLabel of
      FunBind _ [funCase] -> funCase
      FunBind _ _ -> error "mergeFunBinds: function already has several cases !"
      _ -> error "mergeFunBinds : internal error"