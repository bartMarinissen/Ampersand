{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE MultiParamTypeClasses #-} 
{-# LANGUAGE FlexibleInstances #-} 
module Ampersand.Output.ToJSON.Populations 
  (Populations)
where
import           Ampersand.ADL1
import           Ampersand.Basics
import           Ampersand.Output.ToJSON.JSONutils
import           Data.Maybe
import qualified Data.Set as Set
import qualified Data.Text as Text

data Populations = Populations
   { epJSONatoms :: [AtomValuesOfConcept]
   , epJSONlinks :: [PairsOfRelation]
   } deriving (Generic, Show)
data AtomValuesOfConcept = AtomValuesOfConcept
   { avcJSONconcept :: Text.Text
   , avcJSONatoms :: [Text.Text]
   } deriving (Generic, Show)
data PairsOfRelation = PairsOfRelation
   { porJSONrelation :: Text.Text
   , porJSONlinks :: [JPair]
   } deriving (Generic, Show)
data JPair = JPair
   { prJSONsrc :: Text.Text
   , prJSONtgt :: Text.Text
   } deriving (Generic, Show)
instance ToJSON Populations where
  toJSON = amp2Jason
instance ToJSON AtomValuesOfConcept where
  toJSON = amp2Jason
instance ToJSON PairsOfRelation where
  toJSON = amp2Jason
instance ToJSON JPair where
  toJSON = amp2Jason
instance JSON (MultiFSpecs,Bool) Populations where
 fromAmpersand _ (multi,doMeta) = Populations
   { epJSONatoms = map (fromAmpersand multi) (zip (Set.elems $ allConcepts theFSpec) (repeat doMeta))
   , epJSONlinks = map (fromAmpersand multi) (zip (Set.elems $ vrels       theFSpec) (repeat doMeta))
   }
  where 
   theFSpec 
    | doMeta    = fromMaybe ftl (metaFSpec multi)
    | otherwise = userFSpec multi
     where ftl = fatal "There is no grinded fSpec."
instance JSON (A_Concept,Bool) AtomValuesOfConcept where
 fromAmpersand multi (cpt,doMeta) = AtomValuesOfConcept
   { avcJSONconcept = Text.pack (escapeIdentifier . name $ cpt)
   , avcJSONatoms   = map (Text.pack . showValADL) (Set.elems $ atomsBySmallestConcept theFSpec cpt)
   }
  where 
   theFSpec 
    | doMeta    = fromMaybe ftl (metaFSpec multi)
    | otherwise = userFSpec multi
     where ftl = fatal "There is no grinded fSpec."

instance JSON (Relation,Bool) PairsOfRelation where
 fromAmpersand multi (dcl,doMeta) = PairsOfRelation
   { porJSONrelation = Text.pack . showRel $ dcl
   , porJSONlinks = map (fromAmpersand multi) . Set.elems . pairsInExpr theFSpec $ EDcD dcl
   }
  where 
   theFSpec 
    | doMeta    = fromMaybe ftl (metaFSpec multi)
    | otherwise = userFSpec multi
     where ftl = fatal "There is no grinded fSpec."
instance JSON AAtomPair JPair where
  fromAmpersand _ p = JPair
    { prJSONsrc = Text.pack . showValADL . apLeft $ p 
    , prJSONtgt = Text.pack . showValADL . apRight $ p
    }

