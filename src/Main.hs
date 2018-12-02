{-# LANGUAGE LambdaCase        #-}
{-# LANGUAGE OverloadedStrings #-}

module Main where

import           Control.Monad           (forM_)

import qualified Data.Text.Lazy          as T
import qualified Data.Text.Lazy.Encoding as TE
import qualified Data.Text.Lazy.IO       as TIO
import           Data.Text.Lazy.Read     (decimal)

import           System.Environment      (getArgs, getProgName)
import           System.Exit             (exitFailure)
import           System.IO               (stderr)

import           Text.Printf             (HPrintfType, hPrintf, printf)
import           Text.Regex.PCRE         ((=~))

eprintf :: HPrintfType r => String -> r
eprintf = hPrintf stderr

main :: IO ()
main = do
  (input_filename, input_pattern) <- getArgs >>= \case
    [arg1, arg2] -> do
      return (arg1, arg2)
    _ -> do
      arg0 <- getProgName
      eprintf "usage: %s <locs.txt> <pattern>\n" arg0
      exitFailure

  input_lines <- T.lines <$> TIO.readFile input_filename

  forM_ (zip [(1 :: Word) ..] input_lines) $ \(i, inputLine) -> do
    let [filename, lineno'] = T.splitOn ":" inputLine

    lineno <- case decimal lineno' of
      Left _ -> do
        eprintf "error: Invalid line number on line %d: %s\n" i lineno'
        exitFailure
      Right (lineno, _rest) -> return lineno

    currFileLines <- T.lines <$> TIO.readFile (T.unpack filename)

    forM_ (zip [(1 :: Word) .. lineno] currFileLines) $ \(j, line) -> do
      if j == lineno
        then do
          if TE.encodeUtf8 line =~ input_pattern
            then printf "%s:%d\n" filename lineno
            else return ()
        else return ()
