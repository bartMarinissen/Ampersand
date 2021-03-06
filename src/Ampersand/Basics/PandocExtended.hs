{-# LANGUAGE DeriveDataTypeable #-}
module Ampersand.Basics.PandocExtended
   ( PandocFormat(..)
   , Markup(..)
   , aMarkup2String
   , string2Blocks
   )
where 

import           Ampersand.Basics.Languages
import           Ampersand.Basics.Prelude
import           Ampersand.Basics.Version
import           Data.Data
import qualified Data.Text as Text
import           Text.Pandoc hiding (Meta)

data PandocFormat = HTML | ReST | LaTeX | Markdown deriving (Eq, Show, Ord)

data Markup =
    Markup { amLang :: Lang -- No Maybe here!  In the A-structure, it will be defined by the default if the P-structure does not define it. In the P-structure, the language is optional.
             , amPandoc :: [Block]
             } deriving (Show, Eq, Ord, Typeable, Data)

aMarkup2String :: PandocFormat -> Markup -> String
aMarkup2String fmt a = blocks2String fmt False (amPandoc a)

-- | use a suitable format to read generated strings. if you have just normal text, ReST is fine.
-- | defaultPandocReader getOpts should be used on user-defined strings.
string2Blocks :: PandocFormat -> String -> [Block]
string2Blocks defaultformat str
 = case runPure $ theParser (Text.pack (removeCRs str)) of
    Left err ->  fatal ("Proper error handling of Pandoc is still TODO."
                        ++"\n  This particular error is cause by some "++show defaultformat++" in your script:"
                        ++"\n"++show err)
    Right (Pandoc _ blocks) -> blocks
   where
     theParser =
           case defaultformat of
           Markdown  -> readMarkdown def
           ReST      -> readRST      def
           HTML      -> readHtml     def
           LaTeX     -> readLaTeX    def

     removeCRs :: String -> String
     removeCRs [] = []
     removeCRs ('\r' :'\n' : xs) = '\n' : removeCRs xs
     removeCRs (c:xs) = c:removeCRs xs

makePrefix :: PandocFormat -> String
makePrefix format = ":"++show format++":"

-- | write [Block] as String in a certain format using defaultWriterOptions
blocks2String :: PandocFormat -> Bool -> [Block] -> String
blocks2String format writeprefix ec
 = [c | c<-makePrefix format,writeprefix]
   ++ case runPure $ writer def (Pandoc nullMeta ec) of
        Left pandocError -> fatal $ "Pandoc error: "++show pandocError
        Right txt -> Text.unpack txt
   where writer = case format of
            Markdown  -> writeMarkdown
            ReST      -> writeRST
            HTML      -> writeHtml5String
            LaTeX     -> writeLaTeX
