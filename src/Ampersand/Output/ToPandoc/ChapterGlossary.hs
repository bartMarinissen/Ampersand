{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE OverloadedStrings #-}
module Ampersand.Output.ToPandoc.ChapterGlossary
  (chpGlossary)
where
import           Ampersand.Output.ToPandoc.SharedAmongChapters
import qualified Data.Set as Set

chpGlossary :: Int -> FSpec ->  Blocks
chpGlossary _ fSpec
 =      --  *** Header ***
     xDefBlck fSpec Glossary 
  <> simpleTable 
          ( case fsLang fSpec of
               Dutch   ->
                 [ plain "term", plain "definitie", plain "bron"]
               English ->
                 [ plain "term", plain "definition", plain "source"]
          )
          [ [ plain . str . name $ c, plain . str . cddef $ cd, plain . str . cdref $ cd]
          | c<-sortWith name . Set.elems $ concs fSpec, cd<-concDefs fSpec c
          ]
