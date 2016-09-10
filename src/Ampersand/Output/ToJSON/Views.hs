{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE MultiParamTypeClasses #-} 
{-# LANGUAGE FlexibleInstances #-} 
module Ampersand.Output.ToJSON.Views 
    (Views)
where
import Ampersand.Output.ToJSON.JSONutils 
import Ampersand.Core.AbstractSyntaxTree 
import Ampersand.Output.ToJSON.Concepts 

data Views = Views [View] deriving (Generic, Show)
data View = View
  { vwJSONlabel      :: String
  , vwJSONconceptId  :: String
  , vwJSONisDefault  :: Bool
  , vwJSONsegments   :: [Segment]
  } deriving (Generic, Show)
instance ToJSON View where
  toJSON = amp2Jason
instance ToJSON Views where
  toJSON = amp2Jason
instance JSON MultiFSpecs Views where
 froMAmpersand multi _ = Views . map (froMAmpersand multi) 
                               . vviews $ fSpec
   where 
    fSpec = userFSpec multi
    
instance JSON ViewDef View where
 froMAmpersand multi vd = View
  { vwJSONlabel      = name vd
  , vwJSONconceptId  = escapeIdentifier . name . vdcpt $ vd
  , vwJSONisDefault  = vdIsDefault vd
  , vwJSONsegments   = map (froMAmpersand multi) . vdats $ vd
  } 








