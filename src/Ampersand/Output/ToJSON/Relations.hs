{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE MultiParamTypeClasses #-} 
module Ampersand.Output.ToJSON.Relations 
  (Relationz)
where
import           Ampersand.ADL1
import           Ampersand.FSpec.FSpecAux
import           Ampersand.Output.ToJSON.JSONutils 
import           Data.Maybe
import qualified Data.Set as Set

data Relationz = Relationz [RelationJson]deriving (Generic, Show)
data RelationJson = RelationJson
  { relJSONname         :: String
  , relJSONsignature    :: String
  , relJSONsrcConceptId :: String
  , relJSONtgtConceptId :: String
  , relJSONuni          :: Bool
  , relJSONtot          :: Bool
  , relJSONinj          :: Bool
  , relJSONsur          :: Bool
  , relJSONprop         :: Bool
  , relJSONaffectedConjuncts :: [String]
  , relJSONmysqlTable   :: RelTableInfo
  } deriving (Generic, Show)
data RelTableInfo = RelTableInfo -- Contains info about where the relation is implemented in SQL
  { rtiJSONname    :: String
  , rtiJSONtableOf :: Maybe String -- specifies if relation is administrated in table of srcConcept (i.e. "src"), tgtConcept (i.e. "tgt") or its own n-n table (i.e. null).
  , rtiJSONsrcCol  :: TableCol
  , rtiJSONtgtCol  :: TableCol
  } deriving (Generic, Show)
data TableCol = TableCol
  { tcJSONname     :: String
  , tcJSONnull     :: Bool
  , tcJSONunique   :: Bool
  } deriving (Generic, Show)
instance ToJSON Relationz where
  toJSON = amp2Jason
instance ToJSON RelationJson where
  toJSON = amp2Jason
instance ToJSON RelTableInfo where
  toJSON = amp2Jason
instance ToJSON TableCol where
  toJSON = amp2Jason
instance JSON MultiFSpecs Relationz where
 fromAmpersand multi _ = Relationz (map (fromAmpersand multi) (Set.elems $ vrels (userFSpec multi)))
instance JSON Relation RelationJson where
 fromAmpersand multi dcl = RelationJson 
         { relJSONname       = name dcl
         , relJSONsignature  = name dcl ++ (show . sign) dcl
         , relJSONsrcConceptId  = escapeIdentifier . name . source $ dcl 
         , relJSONtgtConceptId  = escapeIdentifier . name . target $ dcl
         , relJSONuni      = isUni bindedExp
         , relJSONtot      = isTot bindedExp
         , relJSONinj      = isInj bindedExp
         , relJSONsur      = isSur bindedExp
         , relJSONprop     = isProp bindedExp
         , relJSONaffectedConjuncts = map rc_id  $ fromMaybe [] (lookup dcl $ allConjsPerDecl fSpec)
         , relJSONmysqlTable = fromAmpersand multi dcl
         }
      where bindedExp = EDcD dcl
            fSpec = userFSpec multi
         
instance JSON Relation RelTableInfo where
 fromAmpersand multi dcl = RelTableInfo
  { rtiJSONname    = name plug
  , rtiJSONtableOf = srcOrtgt
  , rtiJSONsrcCol  = fromAmpersand multi srcAtt
  , rtiJSONtgtCol  = fromAmpersand multi trgAtt
  }
   where fSpec = userFSpec multi
         (plug,srcAtt,trgAtt) = getRelationTableInfo fSpec dcl
         (plugSrc,_)          = getConceptTableInfo fSpec (source dcl)
         (plugTrg,_)          = getConceptTableInfo fSpec (target dcl)
         srcOrtgt
           | plug == plugSrc = Just "src"
           | plug == plugTrg = Just "tgt"
           | otherwise       = Nothing 
instance JSON SqlAttribute TableCol where
 fromAmpersand _ att = TableCol
  { tcJSONname   = attName att
  , tcJSONnull   = attDBNull att
  , tcJSONunique = attUniq att
  }


