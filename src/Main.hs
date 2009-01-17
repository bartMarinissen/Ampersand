 {-# LANGUAGE ScopedTypeVariables#-}
 module Main where
   import System (getArgs,system, ExitCode(ExitSuccess,ExitFailure))
   import Char (toLower)
   import UU_Scanner(scan,initPos)
   import UU_Parsing(parseIO)
   import CommonClasses ( Identified(name))
   import Auxiliaries (chain, commaEng, adlVersion)
   import Typology (Typology(Typ), typology, makeTrees)
   import ADLdef
   import ShowADL
   import ShowHS (showHS)
   import Languages( Lang(English,Dutch))
   import AGtry (sem_Architecture)
   import CC (pArchitecture, keywordstxt, keywordsops, specialchars, opchars)
   import Calc (deriveProofs,triggers)
   import Dataset
   import Data.Fspec
   import FspecDEPRECIATED( 
                   projectClassic
                  ,generateFspecLaTeX
                  ,generateArchLaTeX
                  ,generateGlossaryLaTeX
                  ,funcSpec
              --  ,nDesignPr
             --     ,nServices
             --     ,nFpoints
           --     ,makeFspec
                )
   import HtmlFilenames(fnContext,fnPattern)
   import Graphic(processCdDataModelFile,dotGraph,processDotgraphFile)
   import Atlas (anal)
   import Fspec2LaTeX
   import Fspec2Xml (makeXML_depreciated)
   import ClassDiagram (cdModel,cdDataModel)  
--   import RelBinGen(phpServices)  OBSOLETE as of Jan 1st, 2009 (SJ)
   import ObjBinGen(phpObjServices)
   import ADL2Fspec (makeFspecNew2)
   import Statistics 


   latexOpt :: [String] -> Bool
   latexOpt sws = "-l" `elem` sws
   splitStr :: (String -> Bool) -> [String] -> ([String], [String])
   splitStr f (x:xs) | f x  = (x:yes, no)
                     | True = (yes, x:no)
                     where (yes,no) = splitStr f xs
   splitStr _ [] = ([],[])

   -- WAAROM? Stef, het is gelukt! Hieronder heb je Haddock code neergezet. Prima!
   --         In dit geval is het overigens de vraag of je dat wilt, want nu komt het in de gegenereerde documentatie. Is dat de bedoeling?
   --         Daarnaast nog even een tip: Ook het commentaar met Haddock code er in moet netjes inspringen. Anders gaat Haddock mopperen. Ik heb het inspringen gerepareerd voor je.
   --         En als laatste: Kan je me een ftp-site aanwijzen waarop ik de Haddock code kan neerzetten?
   -- | TODO (SJ) Het volgende is slordige code. Dat moet nog eens netjes worden neergezet, zodat we ook eenvoudig executables kunnen afleiden met een gedeelte van alle functionaliteit.
   main :: IO ()
   main
    = do { -- First, parse the options from the command line:
           a <- getArgs
         ; putStr (chain ", " a++"\n")
         ; let (switches,args') = splitStr ((=="-").take 1) a
         ; let (dbArgs,args) = splitStr ((=="+").take 1) args'
         ; putStr (adlVersion++"\nArguments: "++chain ", " args++"\nSwitches: "++chain ", " switches++"\nDatabase: "++chain ", " (map tail dbArgs))
           
           -- Next, do some checking of commandline options:
         ; if "-checker" `elem` switches && "-beeper" `elem` switches then putStr ("incompatible switches: -checker and -beeper") else
           if length args==0 then putStr ("Please provide a filename (.adl) and a context name\n"++helptext) else
           if length dbArgs>1 then putStr (". This is confusing! please specify 1 database name only.") else

           -- If no errors in the commandline options are found, continue with
           -- parsing of the import file.
      do { let fn = args!!0
               contextname = args!!1
               dbName | null dbArgs = fnOutp
                      | otherwise   = tail (head dbArgs)
               ( _ ,fnSuffix) = (take (length fn-4) fn, drop (length fn-4) fn)
               fnFull = if map Char.toLower fnSuffix /= ".adl" then (fn ++ ".adl") else fn
               fnOutp = take (length fnFull-4) fnFull
         ; inp<-readFile fnFull
         ; putStr ("\n"++fnFull++" is read.\n")
         ; slRes <- parseIO (pArchitecture ("-beeper" `elem` switches))(scan keywordstxt keywordsops specialchars opchars fnFull initPos inp)
         ; let (contexts,errs) = sem_Architecture slRes
         ; let context = if null contexts
                         then error ("!Mistake: no context encountered in input file.\n")
                         else if length args<=1 then head contexts else
                              let cs = [c| c<-contexts, name c==contextname] in
                              if null cs
                              then error ("!Mistake: context "++contextname++" was not encountered in input file.\n")
                              else head cs
         ; let Typ pths = if null contexts then Typ [] else
                          if length args>1 && contextname `elem` map name contexts
                          then typology (ADLdef.isa (head [c| c<-contexts,name c==contextname]))
                          else typology (ADLdef.isa (head contexts))
         ; putStr "\nConcepts:\n" >>(putStr.chain "\n".map show) (makeTrees (Typ (map reverse pths)))

           -- Now we have Contexts with or without errors in it. If there are no errors,
           -- AND the argument matches the context name, then the build is done for that 
           -- context
         ; if null errs 
           then (putStr ("\nNo type errors or cyclic specializations were found.\n")>>
                 if length args==1 && length contexts==1
                 then (( build_DEPRECEATED context switches fnOutp dbName ) >>
                       ( build_NewStyle (makeFspecNew2 context) switches fnOutp dbName )) else
                 if length args==1 && length contexts>1
                 then putStr ("\nPlease specify the name of a context."++
                              "\nAvailable contexts: "++commaEng "and" (map name contexts)++".\n") else
                 if length args>1 && contextname `elem` map name contexts
                 then (( build_DEPRECEATED context switches fnOutp dbName ) >>
                       ( build_NewStyle (makeFspecNew2 context) switches fnOutp dbName ))
                 else putStr ("\nContext "++contextname++" not defined."++
                              "\nPlease specify the name of an available context."++
                              "\nAvailable contexts: "++commaEng "and" (map name contexts)++"."++
                              "\n(Note: context names are case sensitive).\n")
                )
           else putStr ("\nThe type analysis of "++fnFull++" yields errors.\n")>>
                putStr (concat ["!Error of type "++err| err<-errs])>>
                putStr ("Nothing generated, please correct mistake(s) first.\n")
         }}
       where
             -- TODO: De volgende build moet worden 'uitgekleed' door de verschillende 
             --       vertaalslagen via Fspec te laten verlopen. Hiervoor is een functie build_NewStyle gemaakt.
             build_DEPRECEATED :: Context -> [String] -> String -> String -> IO ()
             build_DEPRECEATED context switches filename dbName
              = sequence_ 
                 ([ putStr ("Nothing generated.\n"++helptext) | null switches ] ++
                  [ anal context ("-p" `elem` switches) (lineStyle switches)       | "-atlas" `elem` switches]++
                  [ makeXML_depreciated context                                    | "-XML"   `elem` switches]++
                  [ diagnose context                                               | "-diag"  `elem` switches]++
                  [ functionalSpecLaTeX context (lineStyle switches) (lang switches) filename
                                                                                   | "-fSpec" `elem` switches]++
                  [ archText context (lineStyle switches) (lang switches) filename | "-arch"  `elem` switches]++
                  [ glossary context (lang switches)                               | "-g"     `elem` switches]++
                  [ cdModel context                                                | "-CD"    `elem` switches]++
                  [ phpObjServices context fSpec filename dbName ("./"++filename++"/") True
                                                                                   | "-phpcode" `elem` switches]++
                  [ phpObjServices context fSpec filename dbName ("./"++filename++"/") False
                                                                                   | "-serviceGen" `elem` switches]++
 --                 [ phpServices context filename dbName True True                | "-beeper" `elem` switches]++
 --                 [ phpServices context filename dbName ("-notrans" `elem` switches) False| "-checker" `elem` switches]++
                  [ putStr (deriveProofs context)                                  | "-proofs" `elem` switches]
 --               ++[ projectSpecText context (lang switches) | "-project" `elem` switches]
 --               ++[ csvcontent context | "-csv" `elem` switches]
                 )
                   where
                      fSpec = makeFspecNew2 context
          -- TODO: Onderstaande definities moet op basis van fSpec, niet op basis van context...
                      datasets = makeDatasets context
                      rels  = declarations context
                      ruls  = rules context

             helptext
              = chain "\n"
                [ "The following functionalities are available:"
                , "ADL <myfile>.adl -atlas             generate an atlas, which is a website that"
                , "                                    documents your ADL-script."
                , "ADL <myfile>.adl -fSpec             generate a functional specification, which"
                , "                                    is a PDF-document called myfile.pdf."
                , "ADL <myfile>.adl -phpcode           generate a functional prototype, which is a"
                , "                                    PHP/MySQL application that resides in directory <myfile>"
                , "ADL <myfile>.adl -serviceGen        similar to -phpcode, but generates only those"
                , "                                    services specified in your ADL-script."
                , "ADL <myfile>.adl -services          generate service definitions from scratch and display "
                , "                                    on standard output. You may find this useful"
                , "                                    to start writing SERVICE definitions."
                , "ADL <myfile>.adl -proofs            generate correctness proofs"
                , "ADL <myfile>.adl -Haskell           generate internal data structure, written in Haskell source code"
                , ""
                ]

             build_NewStyle :: Fspc -> [String] -> String -> String -> IO ()
             build_NewStyle fSpec switches filename dbName
              = sequence_ 
                 (--[ anal context ("-p" `elem` switches) (lineStyle switches) | null switches || "-h" `elem` switches]++
                  --[ makeXML_depreciated context| "-XML" `elem` switches]++
                  [ putStr "\n" >> showHaskell fSpec | "-Haskell" `elem` switches] ++ 
                  [ serviceGen fSpec (lang switches) filename| "-services" `elem` switches]
                  --[ diagnose context| "-diag" `elem` switches]++
                  --[ functionalSpecLaTeX context (lineStyle switches) (lang switches) filename| "-fSpec" `elem` switches]++
                  --[ cdModel context | "-CD" `elem` switches]++
                  --[ phpObjServices context fSpec filename dbName ("./"++filename++"/") | "-phpcode" `elem` switches]++
                  --[ phpServices context filename dbName True True | "-beeper" `elem` switches]++
                  --[ phpServices context filename dbName ("-notrans" `elem` switches) False| "-checker" `elem` switches]++
                  --[ deriveProofs context ("-m" `elem` switches)| "-proofs" `elem` switches]
 --               ++[ projectSpecText context (lang switches) | "-project" `elem` switches]
 --               ++[ csvcontent context | "-csv" `elem` switches]
 --               ++[ putStr (show slRes) | "-dump" `elem` switches ]
                 ) 

             lineStyle switches
              | "-crowfoot" `elem` switches = "crowfoot"
              | otherwise                   = "cc"
             lang switches
              | "-NL" `elem` switches = Dutch
              | "-UK" `elem` switches = English
              | otherwise             = Dutch

   diagnose :: Context -> IO()
   diagnose context
    = putStr (showHS "\n>  " context)

   projectSpecText :: Context -> Lang -> IO()
   projectSpecText context language
    = putStrLn ("\nGenerating project plan for "++name context)                >>
      writeFile (name context++".csv") (projectClassic context spec language)  >>
      putStr ("\nMicrosoft Project file "++name context++".csv written... ")
      where
       spec = funcSpec context language
   
   
   showHaskell :: Fspc -> IO ()
   showHaskell fspc
    = putStrLn ("\nGenerating Haskell source code for "++name fspc) >>
      writeFile (baseName++".lhs")
                ("> module Main where"
             ++"\n>  import UU_Scanner"
             ++"\n>  import Classification"
             ++"\n>  import Typology"
             ++"\n>  import ADLdef"
             ++"\n>  import ShowHS (showHS)"
             ++"\n>  import Data.Fspec"
             ++"\n"
             ++"\n>  main = putStr (showHS \"\\n>  \" "++baseName++")"
             ++"\n\n"
             ++">  "++baseName++"\n>   = "++showHS "\n>     " fspc
                ) >>
      putStr ("\nHaskell file "++baseName++".lhs written...\n")
      where
       baseName = "f_Ctx_"++(name fspc)


   functionalSpecLaTeX :: Context -> String ->    Lang ->  String -> IO()
   functionalSpecLaTeX    context    graphicstyle language filename
    = putStr ("\nGenerating functional specification for context "++
              name context++" in the current directory.\n")                   >>
      graphics context (fnContext context) graphicstyle False context         >>   -- generate abbreviated (full==False) class diagram
      sequence_ [ graphics context (fnPattern context pat) graphicstyle True pat   -- generate fully fledge (full==True) class diagram
                | pat<-ctxpats context]                                      >>
      writeFile (filename++".tex") (generateFspecLaTeX context language spec) >>   -- generate LaTeX code
      putStr ("\nLaTeX file "++filename++".tex written... ")                  >>
      processLaTeX2PDF filename                                                    -- crunch the LaTeX file into PDF.
      where
       spec = funcSpec context language

   serviceGen :: Fspc -> Lang ->  String -> IO()
   serviceGen    fSpec    language filename
    = putStr (chain "\n\n" (map showADL (serviceG fSpec)))

   archText :: Context -> String ->    Lang ->  String -> IO()
   archText    context    graphicstyle language filename
    = putStr ("\nGenerating architecture document for context "++
              name context++" in the current directory.\n")                   >>
      graphics context (fnContext context) graphicstyle False context         >>   -- generate abbreviated (full==False) class diagram
      writeFile (filename++".tex") (generateArchLaTeX context language spec)  >>   -- generate LaTeX code
      putStr ("\nLaTeX file "++filename++".tex written... ")                  >>
      processLaTeX2PDF filename                                                    -- crunch the LaTeX file into PDF.
      where
       spec = funcSpec context language

   glossary :: Context -> Lang -> IO()
   glossary    context language
    = putStr ("\nGenerating Glossary for "++name context++" in the current directory.") >>
      writeFile ("gloss"++name context++".tex") (generateGlossaryLaTeX context language)           >>
      putStr ("\nLaTeX file "++"gloss"++name context++".tex written... ") >>
      processLaTeX2PDF ("gloss"++name context)

  --  graphics ::  Context -> String -> String -> Bool ->  { Pattern of Context ??? } -> IO()
   graphics context fnm graphicstyle full b
    = writeFile (fnm++"_CD.dot") (cdDataModel context full "dot" b)  >>
      putStrLn ("Class diagram "++fnm++"_CD.dot written... ")        >>
      processCdDataModelFile  (fnm ++"_CD")                          >>
      writeFile (fnm++".dot") (dotGraph context graphicstyle fnm b)  >>
      putStrLn ("Graphics specification "++fnm++".dot written... ")  >>
      processDotgraphFile  fnm

   processLaTeX2PDF fnm =
      do putStr ("\nProcessing "++fnm++".tex ... :")
         result <- system ("pdflatex -interaction=batchmode "++fnm++".tex")
         case result of
             ExitSuccess   -> putStrLn ("  "++fnm++".pdf created.")
             ExitFailure x -> putStrLn $ "Failure: " ++ show x
         putStr ("\nReprocessing "++fnm++".tex ... :")
         result <- system ("pdflatex -interaction=nonstopmode "++fnm++".tex")
         case result of
             ExitSuccess   -> putStrLn ("  "++fnm++".pdf created.")
             ExitFailure x -> putStrLn $ "Failure: " ++ show x
             
