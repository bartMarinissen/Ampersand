{-# OPTIONS_GHC -Wall #-}
module DatabaseDesign.Ampersand_Prototype.Version
  (ampersandPrototypeVersionBanner,versionNumberPrototype)
where
import DatabaseDesign.Ampersand (versionNumber)
ampersandPrototypeVersionBanner :: String
ampersandPrototypeVersionBanner = "Prototype vs. "++versionNumberPrototype++ "(core vs. "++versionNumber++")"

versionNumberPrototype :: String
versionNumberPrototype = "1.1.0.898" -- #1.#2.#3.#4 : #1 major version; #2 student release version; #3 production fix version (normally 0 ); #4 SVN revision number.
{-
SVN Version text:
PHPconcept is not of class SpecHierarchy (see ticket #29)
This version is compilable with Ampersand vs. 2.0.0.23
-}
