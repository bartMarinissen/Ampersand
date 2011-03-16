{-# OPTIONS_GHC -Wall #-}
module DatabaseDesign.Ampersand_Prototype.Version
  (ampersandPrototypeVersionBanner,versionNumberPrototype)
where
import DatabaseDesign.Ampersand (versionNumber)
ampersandPrototypeVersionBanner :: String
ampersandPrototypeVersionBanner = "Prototype vs. "++versionNumberPrototype++ "(core vs. "++versionNumber++")"

versionNumberPrototype :: String
versionNumberPrototype = "2.0.2.905" -- #1.#2.#3.#4 : #1 major version; #2 student release version; #3 production fix version (normally 0 ); #4 SVN revision number.
{-
SVN Version text:
TICKET #17: wip
This version is compilable with Ampersand vs. 2.0.1.34
-}
