{--
    Convert an AST to XML.
    
    [Module]     Language.CSPM.AstToXml
    [Copyright]  (c) Fontaine 2011
    [License]    BSD3
    
    [Maintainer] Fontaine@cs.uni-duesseldorf.de
    [Stability]  experimental
-}

module Language.CSPM.AstToXML where

import Text.XML.Light.Light(public showTopElement)
import Text.XML.Light.Light
import Data.Data hiding (DataType)
import Data.Generics.Aliases (extQ, ext1Q)
import Language.CSPM.AST
import Language.CSPM.SrcLoc

--- Translate a Module to XML
moduleToXML :: Module a -> Element
moduleToXML m
  = unodeElements "Module"
    [
       unodeElement "moduleDecls" $ astToXML m.moduleDecls
      ,unodeElements "modulePragmas" $ map
         (unodeAttr "Pragma" . Attr (unqual "val"))
         m.modulePragmas
      ,unodeElement "moduleComments" $ astToXML m.moduleComments
    ]

--- Translate an AST node to an XML Element.
--- This is an 'almost' totally generic translation which
--- works for any Haskell type, but it handles some special cases.
astToXML :: Data a => a -> Element
astToXML
  = genericCase-- ((((genericCase `extQ` identToXML) `ext1Q` labelToXML)
    -- `ext1Q` listToXML) `extQ` intToXML) `extQ` commentToXML
  where
    genericCase :: Data a => a -> Element
    genericCase n = unodeElements (showConstr $ toConstr n) $ gmapQ astToXML n

    identToXML :: Ident -> Element
    identToXML x = case x of
      Ident s -> unodeAttr "Ident" (Attr (unqual "unIdent") s)
      UIdent u -> unodeElement "UIdent" $ uniqueIdentToXML u

    labelToXML :: Data a => Labeled a -> Element
    labelToXML l = add_attrs
        ( idAttr : location)
        ( astToXML l.unLabel)
      where 
        idAttr = strAttr "nodeId" $ show l.nodeId.unNodeId
        location = srcLocAttr l.srcLoc

    listToXML :: Data a => [a] -> Element
    listToXML = unodeElements "list" . map astToXML

    intToXML :: Integer -> Element
    intToXML i = unodeAttr "Integer" $ strAttr "val" $ show i

    uniqueIdentToXML :: UniqueIdent -> Element
    uniqueIdentToXML n = unodeAttrs "UniqueIdent"
     [
      strAttr "uniqueIdentId" $ show n.uniqueIdentId
     ,strAttr "bindingSide" $ show n.bindingSide
     ,strAttr "bindingLoc" $ "todo: bindingLoc"
     ,strAttr "idType" $ show n.idType
     ,strAttr "realName" n.realName
     ,strAttr "newName" n.newName
     ,strAttr "prologMode" $ show n.prologMode
     ,strAttr "bindType" $ show n.bindType
     ]

    strAttr a s = Attr (unqual a) s

    srcLocAttr :: SrcLoc.SrcLoc -> [Attr]
    srcLocAttr loc = case loc of
      SrcLoc.TokPos {} -> [
          locAttr "sLine" $ SrcLoc.getStartLine loc
        , locAttr "sCol" $ SrcLoc.getStartCol loc
        , locAttr "sPos" $ SrcLoc.getStartOffset loc
        , locAttr "len" $ SrcLoc.getTokenLen loc
        ]
      SrcLoc.TokSpan {} -> [
          locAttr "sLine" $ SrcLoc.getStartLine loc
        , locAttr "sCol" $ SrcLoc.getStartCol loc
        , locAttr "eLine" $ SrcLoc.getEndLine loc
        , locAttr "eCol" $ SrcLoc.getEndCol loc
        , locAttr "sPos" $ SrcLoc.getStartOffset loc
        , locAttr "len" $ SrcLoc.getTokenLen loc
        ]
      SrcLoc.FixedLoc {} -> [
          locAttr "sLine" $ SrcLoc.getStartLine loc
        , locAttr "sCol" $ SrcLoc.getStartCol loc
        , locAttr "eLine" $ SrcLoc.getEndLine loc
        , locAttr "eCol" $ SrcLoc.getEndCol loc
        , locAttr "sPos" $ SrcLoc.getStartOffset loc
        , locAttr "len" $ SrcLoc.getTokenLen loc
        ]
      _ -> []

    locAttr s i = Attr (unqual s) $ show i

    commentToXML :: (Comment,SrcLoc.SrcLoc) -> Element
    commentToXML (comment,loc)
       = add_attrs (srcLocAttr loc) $ case comment of
      LineComment c -> unodeAttr "LineComment" $ strAttr "val" c
      BlockComment c -> unodeAttr "BlockComment" $ strAttr "val" c
      PragmaComment c -> unodeAttr "PragmaComment" $ strAttr "val" c
