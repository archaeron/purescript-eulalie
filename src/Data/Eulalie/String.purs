module Data.Eulalie.String where

import Prelude

import Control.Alt ((<|>))
import Control.Apply ((*>))
import Data.Foldable (fold)
import Data.Int as Int
import Data.Maybe (Maybe(..))
import Data.String as String
import Global (readFloat, isNaN)

import Data.Eulalie.Char as Char
import Data.Eulalie.Parser (Parser(), expected, maybe, fail, item)

-- |Matches the given parser zero or more times, returning a string of the
-- |entire match.
many :: Parser String -> Parser String
many parser = maybe $ many1 parser

-- |Matches the given parser one or more times, returning a string of the
-- |entire match.
many1 :: Parser String -> Parser String
many1 parser = do
  head <- parser
  tail <- many parser
  return (head ++ tail)

-- |Turns a parser of `Char` into a parser of `String`.
fromChar :: Parser Char -> Parser String
fromChar parser = String.fromChar <$> parser

-- |Matches the exact `Char` provided, returning it as a string.
char :: Char -> Parser String
char = fromChar <<< Char.char

-- |Matches any one character except the one provided, returning a string.
notChar :: Char -> Parser String
notChar = fromChar <<< Char.notChar

-- |Matches the exact string provided.
string :: String -> Parser String
string s = expected (string' s) $ "\"" ++ s ++ "\""
  where string' :: String -> Parser String
        string' s = case String.charAt 0 s of
          Nothing -> return ""
          Just c -> do
            Char.char c
            string' $ String.drop 1 s
            return s

-- |Matches zero or more whitespace characters.
spaces :: Parser String
spaces = Char.many Char.space

-- |Matches one or more whitespace characters.
spaces1 :: Parser String
spaces1 = expected (Char.many1 Char.space) "whitespace"

-- |Matches zero or more non-whitespace characters.
notSpaces :: Parser String
notSpaces = Char.many Char.notSpace

-- |Matches one or more non-whitespace characters.
notSpaces1 :: Parser String
notSpaces1 = expected (Char.many1 Char.notSpace)
             "one or more non-whitespace characters"

-- |Parses a positive or negative integer.
int :: Parser Int
int = expected int' "an integer"
  where int' = do
          r <- fold [ maybe (char '-'), Char.many1 Char.digit ]
          case Int.fromString r of
            Just i -> return i
            _ -> fail

-- |Parses a positive or negative floating point number.
float :: Parser Number
float = expected float' "a number"
  where float' = do
          r <- fold [ maybe (char '-'),
                         Char.many Char.digit,
                         maybe $ fold [ char '.', Char.many1 Char.digit ]
                      ]
          case readFloat r of
            n | isNaN n -> fail
            n -> return n

-- |Parses a double quoted string, with support for escaping double quotes
-- |insite it, and returns the inner string. Does not perform any other form
-- |of string escaping.
quotedString :: Parser String
quotedString = expected qs "a quoted string"
  where qs = do
          char '"'
          s <- many $ (char '\\' *> fromChar item) <|> notChar '"'
          char '"'
          return s
