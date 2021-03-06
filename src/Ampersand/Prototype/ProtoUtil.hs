{-# LANGUAGE FlexibleInstances #-}
module Ampersand.Prototype.ProtoUtil
         ( getGenericsDir
         , writePrototypeAppFile
         , copyDirRecursively, copyDeepFile, removeAllDirectoryFiles, getProperDirectoryContents
         , escapeIdentifier,commentBlock,strReplace
         , addSlashes
         , indentBlock,addToLast
         , indentBlockBetween
         , phpIndent,showPhpStr,escapePhpStr,showPhpBool, showPhpMaybeBool
         , installComposerLibs
         ) where
 
import           Ampersand.Basics
import           Ampersand.Misc
import           Data.List
import           Data.Monoid
import qualified Data.Text as Text
import           System.Directory
import qualified System.Exit as SE (ExitCode(..))
import           System.FilePath
import           System.Process


getGenericsDir :: Options -> String
getGenericsDir opts = 
  dirPrototype opts </> "generics" 

writePrototypeAppFile :: Options -> String -> String -> IO ()
writePrototypeAppFile opts relFilePath content =
 do { verboseLn opts ("  Generating "<>relFilePath)
    ; let filePath = getAppDir opts </> relFilePath
    ; createDirectoryIfMissing True (takeDirectory filePath)
    ; writeFile filePath content
    }
   
getAppDir :: Options -> String
getAppDir opts =
  dirPrototype opts </> "app" </> "project"
  
-- Copy entire directory tree from srcBase/ to tgtBase/, overwriting existing files, but not emptying existing directories.
-- NOTE: tgtBase specifies the copied directory target, not its parent
copyDirRecursively :: FilePath -> FilePath -> Options -> IO ()
copyDirRecursively srcBase tgtBase opts = copy ""
  where copy fileOrDirPth = 
         do { let srcPath = srcBase </> fileOrDirPth
                  tgtPath = tgtBase </> fileOrDirPth
            ; isDir <- doesDirectoryExist srcPath
            ; if isDir then 
               do { createDirectoryIfMissing True tgtPath
                  ; verboseLn opts $ " Copying dir... " ++ srcPath
                  ; fOrDs <- getProperDirectoryContents srcPath
                  ; mapM_ (\fOrD -> copy $ fileOrDirPth </> fOrD) fOrDs
                  }
              else
               do { verboseLn opts $ "  file... " ++ fileOrDirPth
                  ; copyFile srcPath tgtPath -- directory will exist, so no need for copyDeepFile
                  }
            }
            
-- Copy file while creating all subdirectories on the target path (if non-existent)
copyDeepFile :: FilePath -> FilePath -> Options -> IO ()
copyDeepFile srcPath tgtPath opts =
 do { verboseLn opts $ " Copying file... " ++ srcPath ++ " -> " ++ tgtPath
    ; createDirectoryIfMissing True (takeDirectory tgtPath)
    ; copyFile srcPath tgtPath
    }

-- Remove all files in directory dirPath, but don't enter subdirectories (for which a warning is emitted.)
removeAllDirectoryFiles :: FilePath -> IO ()
removeAllDirectoryFiles dirPath =
 do { dirContents <- getProperDirectoryContents dirPath
    ; mapM_ removeDirectoryFile dirContents 
    }
  where removeDirectoryFile path = 
         do { let absPath = dirPath </> path
            ; isDir <- doesDirectoryExist absPath
            ; if isDir then
                putStrLn $ "WARNING: directory '"<>dirPath<>"' contains a subdirectory '"<>path<>"' which is not cleared."
              else
                removeFile absPath
            }
     
getProperDirectoryContents :: FilePath -> IO [String]
getProperDirectoryContents pth = 
    filter (`notElem` [".","..",".svn"]) 
       <$> getDirectoryContents pth

commentBlock :: [String]->[String]
commentBlock ls = ["/*"<>replicate lnth '*'<>"*\\"]
                     <> ["* "<>strReplace "*/" "**" line<>replicate (lnth - length line) ' '<>" *" | line <- ls]
                     <> ["\\*"<>replicate lnth '*'<>"*/"]
   where
     lnth = foldl max 0 (map length ls)
indentBlock :: Int -> [String] -> [String]
indentBlock i = map (replicate i ' ' <>)

-- | will put the block after the first string, and put the second after the block
-- | If the block is just 1 line, indentBlockBetween will return just 1 line as well
indentBlockBetween :: Text.Text -- ^ precedes the block
                   -> Text.Text -- ^ comes at the end of the block
                   -> [Text.Text] -- ^ the block itself, (will be indented)
                   -> Text.Text -- ^ result
indentBlockBetween pre post [] = pre<>post
indentBlockBetween pre post [s] = pre<>s<>post
indentBlockBetween pre post block
 = Text.intercalate (phpIndent (Text.length pre)) ((pre<>head block):(init rest<>[last rest<>post]))
 where  rest = tail block

strReplace :: String -> String -> String -> String
strReplace _ _ "" = ""
strReplace "" _ str = str
strReplace src dst inp
    = process inp
      where
        n = length src
        process "" = ""
        process st@(c:cs)
          | src `isPrefixOf` st = dst <> process (drop n st)
          | otherwise           = c:process cs

phpIndent :: Int -> Text.Text
phpIndent i
 | i < 0     = Text.pack " " --space instead of \n
 | otherwise = Text.pack $ '\n':replicate i ' '


addSlashes :: Text.Text -> Text.Text
addSlashes = Text.pack . addSlashes' . Text.unpack
  where
    addSlashes' ('\'': cs) = "\\'"<>addSlashes' cs
    addSlashes' ('"': cs) = "\\\""<>addSlashes' cs
    addSlashes' ('\\': cs) = "\\\\"<>addSlashes' cs
    addSlashes' (c:cs) = c:addSlashes' cs
    addSlashes' "" = ""

addToLast :: [a] -> [[a]] -> [[a]]
addToLast _ [] = fatal "addToLast: empty list"
addToLast s as = init as<>[last as<>s]

showPhpStr :: Text.Text -> Text.Text
showPhpStr str = q<>Text.pack (escapePhpStr (Text.unpack str))<>q
  where q = Text.pack "'"

-- NOTE: we assume a single quote php string, so $ and " are not escaped
escapePhpStr :: String -> String
escapePhpStr ('\'':s) = "\\'" <> escapePhpStr s
escapePhpStr ('\\':s) = "\\\\" <> escapePhpStr s
escapePhpStr (c:s)    = c: escapePhpStr s
escapePhpStr []       = []
-- todo: escape everything else (unicode, etc)

showPhpBool :: Bool -> String
showPhpBool b = if b then "true" else "false"

showPhpMaybeBool :: Maybe Bool -> String
showPhpMaybeBool Nothing = "null"
showPhpMaybeBool (Just b) = showPhpBool b


installComposerLibs :: Options -> IO()
installComposerLibs opts =
  do curPath <- getCurrentDirectory
     verboseLn opts $ "current directory: "++curPath
     verbose opts "  Trying to download and install Composer libraries..."
     (exit_code, stdout', stderr') <- readCreateProcessWithExitCode myProc ""
     case exit_code of
       SE.ExitSuccess   -> do verboseLn opts $
                               " Succeeded." <> (if null stdout' then " (stdout is empty)" else "") 
                              verboseLn opts stdout'
       SE.ExitFailure _ -> failOutput (exit_code, stdout', stderr')

   where
     myProc :: CreateProcess
     myProc = CreateProcess 
       { cmdspec = ShellCommand $ "composer install --prefer-dist --no-dev --profile --working-dir="<>composerTargetPath
       , cwd = Nothing
       , env = Nothing
       , std_in = Inherit
       , std_out = Inherit
       , std_err = Inherit
       , close_fds = False
       , create_group = False
       , delegate_ctlc = True
       , detach_console = False
       , create_new_console = False
       , new_session = False
       , child_group = Nothing
       , child_user = Nothing
       , use_process_jobs = False
       }
     composerTargetPath = dirPrototype opts
     failOutput (exit_code, stdout', stderr') =
        exitWith . FailedToInstallComposer  $
            [ "Failed!"
            , "composerTargetPath: "++composerTargetPath
            , "Exit code of trying to install Composer: "<>show exit_code<>". "
            ] ++ 
            (if null stdout' then [] else "stdout:" : lines stdout') ++
            (if null stderr' then [] else "stderr:" : lines stderr') ++
            [ "Possible solutions to fix your prototype:"
            , "  1) Make sure you have composer installed. (Details can be found at https://getcomposer.org/download/)"
            , "  2) Make sure you have an active internet connection."
            , "  3) If you previously built another Ampersand prototype succesfully, you could try to copy the lib directory from it into you prototype manually."
            ]