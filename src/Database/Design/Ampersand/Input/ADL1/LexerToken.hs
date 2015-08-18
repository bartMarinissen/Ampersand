module Database.Design.Ampersand.Input.ADL1.LexerToken
    ( Token(..)
    , Lexeme(..)
    , lexemeText
    , initPos
    , FilePos(..)
    ) where

import Database.Design.Ampersand.Input.ADL1.FilePos (FilePos(..), initPos)
import Text.Parsec()

-- | The Ampersand token
data Token = Tok { tokLex :: Lexeme  -- ^ The lexeme
                 , tokPos :: FilePos -- ^ The position where the lexeme was found
                 }

instance Show Token where
  show (Tok lx p) = show lx ++ " " ++ show p

-- | The Ampersand Lexemes
data Lexeme  = LexSymbol      Char    -- ^ A symbol
             | LexOperator    String  -- ^ An operator
             | LexKeyword     String  -- ^ A keyword
             | LexString      String  -- ^ A quoted string
             | LexExpl        String  -- ^ An explanation
             | LexSingleton   String  -- ^ An atomvalue in an Expression
             | LexDecimal     Int     -- ^ A decimal number
             | LexOctal       Int     -- ^ An octal number
             | LexHex         Int     -- ^ A hexadecimal number
             | LexConId       String  -- ^ An upper case identifier
             | LexVarId       String  -- ^ A lower case identifier
  deriving (Eq, Ord)

instance Show Lexeme where
    show x = case x of
         LexSymbol   val -> "symbol "                ++ "'"  ++     [val] ++ "'"
         LexOperator val -> "operator "              ++ "'"  ++      val  ++ "'"
         LexKeyword  val -> "keyword "               ++         show val
         LexString   val -> "string "                ++ "\"" ++      val  ++ "\""
         LexExpl     val -> "explanation "           ++ "{+" ++      val  ++ "+}"
         LexSingleton val -> "singleton "            ++ "'"  ++      val  ++ "'"
         LexDecimal   _  -> "integer "               ++   lexemeText  x
         LexOctal     _  -> "octal "                 ++   lexemeText  x
         LexHex       _  -> "hexadecimal "           ++   lexemeText  x
         LexVarId    val -> "lower case identifier " ++              val
         LexConId    val -> "upper case identifier " ++              val

-- A Stream instance is responsible for maintaining the "position within the stream" in the stream state (Token).
-- This is trivial unless you are using the monad in a non-trivial way.
-- instance (Monad m) => Stream [Token] m Char where
--  uncons :: (Monad m) => [Token] -> m (Maybe (Char, [Token]))
--    uncons []     = return $ Nothing
--    uncons (t:ts) = return $ Just (t,ts)

-- | Retrieves the text from a lexeme
lexemeText :: Lexeme -- ^ The lexeme
           -> String -- ^ The text contained in the lexeme
lexemeText l = case l of
         LexSymbol   val -> [val]
         LexOperator val -> val
         LexKeyword  val -> val
         LexString   val -> val
         LexExpl     val -> val
         LexSingleton val -> val
         LexDecimal  val -> show val
         LexOctal    val -> "0o" ++ toBase 8  val
         LexHex      val -> "0x" ++ toBase 16 val
         LexConId    val -> val
         LexVarId    val -> val

toBase :: Integral a => Show a => a -> a -> String
toBase b x = conv x ""
       where conv 0 str = str
             conv n str = conv (n `div` b) (show (n `mod` b) ++ str)
