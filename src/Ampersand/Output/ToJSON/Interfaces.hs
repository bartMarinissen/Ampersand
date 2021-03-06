{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE MultiParamTypeClasses #-} 
{-# LANGUAGE FlexibleInstances #-} 
module Ampersand.Output.ToJSON.Interfaces 
   (Interfaces)
where
import Ampersand.Output.ToJSON.JSONutils 
import Ampersand.ADL1
import Ampersand.FSpec.ToFSpec.NormalForms
import Ampersand.FSpec.ToFSpec.Calc

data Interfaces = Interfaces [JSONInterface] deriving (Generic, Show)
data JSONInterface = JSONInterface
  { ifcJSONinterfaceRoles     :: [String]
  , ifcJSONboxClass           :: Maybe String
  , ifcJSONifcObject          :: JSONObjectDef
  } deriving (Generic, Show)
data JSONObjectDef = 
  JSONObjectDef
    { ifcJSONtype               :: String
    , ifcJSONtxt                :: Maybe String
    , ifcJSONid                 :: String
    , ifcJSONlabel              :: String
    , ifcJSONviewId             :: Maybe String
    , ifcJSONNormalizationSteps :: Maybe [String] -- Not used in frontend. Just informative for analisys
    , ifcJSONrelation           :: Maybe String
    , ifcJSONrelationIsFlipped  :: Maybe Bool
    , ifcJSONcrud               :: Maybe JSONCruds
    , ifcJSONexpr               :: Maybe JSONexpr
    , ifcJSONsubinterfaces      :: Maybe JSONSubInterface
    } deriving (Generic, Show)
data JSONSubInterface = JSONSubInterface
  { subJSONboxClass           :: Maybe String
  , subJSONifcObjects         :: Maybe [JSONObjectDef]
  , subJSONrefSubInterfaceId  :: Maybe String
  , subJSONrefIsLinkTo        :: Maybe Bool
  } deriving (Generic, Show)
data JSONCruds = JSONCruds
  { crudJSONread              :: Bool
  , crudJSONcreate            :: Bool
  , crudJSONupdate            :: Bool
  , crudJSONdelete            :: Bool
  } deriving (Generic, Show)
data JSONexpr = JSONexpr
  { exprJSONsrcConceptId      :: String
  , exprJSONtgtConceptId      :: String
  , exprJSONisUni             :: Bool
  , exprJSONisTot             :: Bool
  , exprJSONisIdent           :: Bool
  , exprJSONquery             :: String
  } deriving (Generic, Show)

instance ToJSON JSONSubInterface where
  toJSON = amp2Jason
instance ToJSON Interfaces where
  toJSON = amp2Jason
instance ToJSON JSONInterface where
  toJSON = amp2Jason
instance ToJSON JSONObjectDef where
  toJSON = amp2Jason
instance ToJSON JSONCruds where
  toJSON = amp2Jason
instance ToJSON JSONexpr where
  toJSON = amp2Jason
  
instance JSON MultiFSpecs Interfaces where
 fromAmpersand multi _ = Interfaces (map (fromAmpersand multi) (interfaceS fSpec ++ interfaceG fSpec))
   where fSpec = userFSpec multi

instance JSON SubInterface JSONSubInterface where
 fromAmpersand multi si = 
   case si of 
     Box{} -> JSONSubInterface
       { subJSONboxClass           = siMClass si
       , subJSONifcObjects         = Just . map (fromAmpersand multi) . siObjs $ si
       , subJSONrefSubInterfaceId  = Nothing
       , subJSONrefIsLinkTo        = Nothing
       }
     InterfaceRef{} -> JSONSubInterface
       { subJSONboxClass           = Nothing
       , subJSONifcObjects         = Nothing
       , subJSONrefSubInterfaceId  = Just . escapeIdentifier . siIfcId $ si
       , subJSONrefIsLinkTo        = Just . siIsLink $ si
       }
instance JSON Interface JSONInterface where
 fromAmpersand multi interface = JSONInterface
  { ifcJSONinterfaceRoles     = map name . ifcRoles $ interface
  , ifcJSONboxClass           = Nothing -- todo, fill with box class of toplevel ifc box
  , ifcJSONifcObject          = fromAmpersand multi (BxExpr $ ifcObj interface)
  }

instance JSON Cruds JSONCruds where
 fromAmpersand _ crud = JSONCruds
  { crudJSONread              = crudR crud
  , crudJSONcreate            = crudC crud
  , crudJSONupdate            = crudU crud
  , crudJSONdelete            = crudD crud
  }
  
instance JSON BoxExp JSONexpr where
 fromAmpersand multi object =
    JSONexpr
        { exprJSONsrcConceptId = escapeIdentifier . name $ srcConcept
        , exprJSONtgtConceptId = escapeIdentifier . name $ tgtConcept
        , exprJSONisUni        = isUni normalizedInterfaceExp
        , exprJSONisTot        = isTot normalizedInterfaceExp
        , exprJSONisIdent      = isIdent normalizedInterfaceExp
        , exprJSONquery        = query
        }
      where
        opts = getOpts fSpec
        fSpec = userFSpec multi
        query = broadQueryWithPlaceholder fSpec object{objExpression=normalizedInterfaceExp}
        normalizedInterfaceExp = conjNF opts $ objExpression object
        (srcConcept, tgtConcept) =
          case getExpressionRelation normalizedInterfaceExp of
            Just (src, _ , tgt, _) ->
              (src, tgt)
            Nothing -> (source normalizedInterfaceExp, target normalizedInterfaceExp) -- fall back to typechecker type
 
instance JSON BoxItem JSONObjectDef where
 fromAmpersand multi obj =
   case obj of 
     BxExpr object' -> JSONObjectDef
      { ifcJSONtype               = "ObjExpression"
      , ifcJSONid                 = escapeIdentifier . name $ object
      , ifcJSONlabel              = name object
      , ifcJSONviewId             = fmap name viewToUse
      , ifcJSONNormalizationSteps = Just $ showPrf showA.cfProof.objExpression $ object 
      , ifcJSONrelation           = fmap (showRel . fst) mEditableDecl
      , ifcJSONrelationIsFlipped  = fmap            snd  mEditableDecl
      , ifcJSONcrud               = Just $ fromAmpersand multi (objcrud object)
      , ifcJSONexpr               = Just $ fromAmpersand multi object
      , ifcJSONsubinterfaces      = fmap (fromAmpersand multi) (objmsub object)
      , ifcJSONtxt                = Nothing
      }
      where
        opts = getOpts fSpec
        fSpec = userFSpec multi
        viewToUse = case objmView object of
                    Just nm -> Just $ lookupView fSpec nm
                    Nothing -> getDefaultViewForConcept fSpec tgtConcept
        normalizedInterfaceExp = conjNF opts $ objExpression object
        (tgtConcept, mEditableDecl) =
          case getExpressionRelation normalizedInterfaceExp of
            Just (_ , decl, tgt, isFlipped') ->
              (tgt, Just (decl, isFlipped'))
            Nothing -> (target normalizedInterfaceExp, Nothing) -- fall back to typechecker type
        object = substituteReferenceObjectDef fSpec object'
     BxTxt object -> JSONObjectDef
      { ifcJSONtype               = "ObjText"
      , ifcJSONid                 = escapeIdentifier . name $ object
      , ifcJSONlabel              = name object
      , ifcJSONviewId             = Nothing
      , ifcJSONNormalizationSteps = Nothing
      , ifcJSONrelation           = Nothing
      , ifcJSONrelationIsFlipped  = Nothing
      , ifcJSONcrud               = Nothing
      , ifcJSONexpr               = Nothing
      , ifcJSONsubinterfaces      = Nothing
      , ifcJSONtxt                = Just $ objtxt object
      }
