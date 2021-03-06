module Ampersand.Output.Statistics (Statistics(..)) where

import Ampersand.Basics
import Ampersand.ADL1
import Ampersand.FSpec.FPA
import Ampersand.FSpec.FSpec

-- TODO Deze module moet nog verder worden ingekleurd...

class Statistics a where
  nInterfaces :: a -> Int      -- ^ The number of interfaces in a
  nPatterns :: a -> Int      -- ^ The number of patterns in a
  nFpoints :: a -> Int      -- ^ The number of function points in a

instance Statistics a => Statistics [a] where
  nInterfaces xs = sum (map nInterfaces xs)
  nPatterns   xs = sum (map nPatterns xs)
  nFpoints    xs = sum (map nFpoints xs)

instance Statistics FSpec where
  nInterfaces _     = 0 --TODO -> check correctness
  nPatterns   fSpec = nPatterns (vpatterns fSpec)
  nFpoints    fSpec = sum (map nFpoints (interfaceS fSpec++interfaceG fSpec))
                --       + sum [fPoints (fpa plug) | InternalPlug plug <- plugInfos fSpec]
-- TODO Deze module moet nog verder worden ingekleurd...

instance Statistics Pattern where
  nInterfaces _ = 0 --TODO -> check correctness
  nPatterns   _ = 1
  nFpoints   _  = fatal "function points are not defined for patterns at all."


-- \***********************************************************************
-- \*** Properties with respect to: Dataset                       ***
-- \*** TODO: both datasets and interfaces are represented as BoxItem. This does actually make a difference for the function point count, so we have work....
instance Statistics Interface where
  nInterfaces _ = 1
  nPatterns   _ = 0
  nFpoints ifc  = fpVal $ fpaInterface ifc

--   instance Statistics BoxItem where
--    nInterfaces (Obj{objmsub=Nothing}) = 2 -- this is an association, i.e. a binary relation --TODO -> check correctness
--    nInterfaces _ = 4 -- this is an entity with one or more attributes. --TODO -> check correctness
--    nPatterns   _ = 0
--    nFpoints    _ = fatal "function points are not defined for ObjectDefs at all."
