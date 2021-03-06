module Ampersand.Output.ToPandoc.ChapterInterfaces
  ( 
   chpInterfacesBlocks
  )
where
import           Ampersand.ADL1
import           Ampersand.Classes.Relational
import           Ampersand.FSpec.Crud
import           Ampersand.FSpec.FPA
import           Ampersand.Output.PandocAux
import           Ampersand.Output.ToPandoc.SharedAmongChapters
import           Data.List
import qualified Data.Set as Set

chpInterfacesBlocks :: FSpec -> Blocks
chpInterfacesBlocks fSpec = 
     --  *** Header ***
      xDefBlck fSpec Interfaces
   <> mconcat (map interfaceChap regularInterfaces)
  where
    regularInterfaces :: [Interface]
    regularInterfaces = interfaceS fSpec
    
    lang = Dutch -- TODO: add English labels and use (fsLang fSpec) here
      
    interfaceChap :: Interface -> Blocks
    interfaceChap ifc
     =  xDefBlck fSpec (XRefInterfacesInterface ifc)  <>
        ifcIntro ifc <>
        docInterface ifc
      
    ifcIntro :: Interface -> Blocks
    ifcIntro ifc
     =  introBlocks <>
        purposes2Blocks (getOpts fSpec) purps        
       where purps = purposesDefinedIn fSpec lang ifc
 
             introBlocks :: Blocks
             introBlocks = fromList $
               case lang of
                 Dutch   -> [Para
                             [ Str $ "Dit hoofdstuk bevat de documentatie voor de interface "++ quoteName ifc++"."
                             ]]
                 English -> [Para
                             [ Str $ "This chapter contains the documentation for the interface "++ quoteName ifc++"."
                             ]]

    docInterface :: Interface -> Blocks
    docInterface ifc =
       plainText ( "De interface is beschikbaar voor " <> showRoles (ifcRoles ifc) <> ".") <>
      (if null $ ifcControls ifc
       then plainText "Voor deze interface hoeven geen regels gecontroleerd te worden."
       else plainText "Voorafgaand aan het afsluiten van een transactie (commit), moet aan de volgende regels voldaan zijn:" <>  
              (bulletList . map plainText . nub) [rrnm rule | conj <- ifcControls ifc, rule <- Set.elems $ rc_orgRules conj, r_usr rule == UserDefined]) <>
      (if genFPAChap (getOpts fSpec)
       then (plain . strong . text) "Functiepunten:" <>
            plainText ("Deze interface is gerubriceerd als " ++ showLang lang (fpType interfaceFP) ++
                       " " ++ showLang lang (fpComplexity interfaceFP) ++ 
                       ", en is daarmee " ++ show (fpVal interfaceFP) ++ " functiepunten waard.")
       else mempty
      ) <>
      docCrudMatrix ifc <>
      (plain . strong . text) "Interfacestructuur:" <>
      docInterfaceObjects (ifcRoles ifc) [] (ifcObj ifc)
      where interfaceFP = fpaInterface ifc

    docInterfaceObjects :: [Role] -> [Int] -> BoxExp -> Blocks
    docInterfaceObjects roles hierarchy object =
      case hierarchy of
        [] -> plain . text $ "Interface voor een waarde van type " ++ quoteName (target iExp) ++ "."
              -- TODO: unclear what we want to do here. Probably want to hide "ONE". Do we need to take multiplicites into account? (e.g. waarden)  
        _  -> plain . strong . fromList $ [Str $ intercalate "." (map show hierarchy) <> " " <> objectName]
      <> interfaceObjDoc <>
      mconcat subInterfaceDocs
      where objectName = let nm = name object in if null nm then "<Naamloos>" else nm
      
            interfaceObjDoc :: Blocks
            interfaceObjDoc =
              mconcat $
                [ plainText  $ fieldDescr ++ quoteName (target iExp) ++"."
                ] ++
                
                case navigationDocs of
                  []               -> []
                  navDocs@(_:rest) -> 
                    plainText ("Hiervandaan kan genavigeerd worden naar interface"++(if null rest then "" else "s")++":") :
                    [ bulletList navDocs ]
                ++
                [ plainText "De bijbehorende Ampersand expressie is: ", plain . code $ showA iExp ] ++
                [ plainText $ fieldRef ++ " bestaat uit " ++ show (length subInterfaceDocs) ++ " deelveld"++ (if len>1 then "en" else "") ++":"
                | let len = length subInterfaceDocs, len > 0 ]
              where (fieldDescr,fieldRef) 
                      | isSur iExp && isUni iExp = ("Een verplicht veld van type ", "Dit veld")
                      | isSur iExp               = ("Een lijst van 1 of meer velden van type ", "Elk veld")
                      |               isUni iExp = ("Een optioneel veld van type ", "Dit veld")
                      | otherwise                = ("Een lijst van 0 of meer velden van type ", "Elk veld")
                    navigationDocs = [ plainText $ quoteName navIfc ++ " (voor " ++ showRoles sharedRoles ++ ")" 
                                     | navIfc <- regularInterfaces
                                     , source (objExpression . ifcObj $ navIfc) == target iExp
                                     , let sharedRoles = ifcRoles navIfc `intersect` roles
                                     , not . null $ sharedRoles
                                     ]

            iExp = conjNF (getOpts fSpec) $ objExpression object
                    
            subInterfaceDocs = docMSubInterface roles hierarchy (objmsub object)

    docMSubInterface :: [Role] -> [Int] -> Maybe SubInterface -> [Blocks]
    docMSubInterface roles hierarchy subIfc =
      case subIfc of
        Nothing -> []
        Just si ->
          case si of
           InterfaceRef{} -> 
             [ plainText $ (if siIsLink si then "LINKTO " else "")++"REF "++siIfcId si ] -- TODO: handle InterfaceRef
           Box{} -> 
             [ docInterfaceObjects roles (hierarchy ++[i]) obj | (obj,i) <- zip [e | BxExpr e <- siObjs si] [1..] ]

    docCrudMatrix :: Interface -> Blocks
    docCrudMatrix ifc = mconcat
      [ plain . strong . text $ "CRUD matrix:"
      , simpleTable 
          [ plainText "Concept", plainText "C", plainText "R", plainText "U", plainText "D" ]
          [ [plainText $ name cncpt, checkMark isC, checkMark isR, checkMark isU, checkMark isD ]
          | (cncpt, isC, isR, isU, isD) <- getCrudObjectsForInterface (crudInfo fSpec) ifc
          ]
      ]
      where checkMark isChecked = if isChecked then plain $ fromList [Math InlineMath "\\surd"] else mempty
    

-- TODO: Maybe we should create a more general version of this function (might already exist, but I couldn't find it)
showRoles :: [Role] -> String
showRoles roles = case roles of
                    [] -> "alle rollen"
                    [rl] -> "de rol " ++ quoteName rl
                    [rl1,rl2] -> "de rollen " ++ quoteName rl1 ++ " en " ++ quoteName rl2
                    (rl1:rls) -> "de rollen " ++ quoteName rl1 ++ 
                                 (concat . reverse $ zipWith (++) (", en ": repeat ", ") $ reverse $ map quoteName rls)

--TODO: make inlines, then use singleQuoted 
quoteName :: Named a => a -> String
quoteName x = "``"++name x++"''"
