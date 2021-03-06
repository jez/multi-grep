structure Options =
struct
  local
    open Prelude
    infixr 0 $
  in

  val version = "0.2.2"

  fun usage () = String.concatWith "\n"
    [ "Usage:"
    , "  "^(CommandLine.name ())^" [options] <pattern> [<locs.txt>]"
    , ""
    , "Searches in the mentioned lines for the pattern and prints the lines"
    , "that contain a match."
    , ""
    , "Arguments:"
    , "  <pattern>      An AWK-compatible[1] regular expression."
    , "  <locs.txt>     The name of a file with lines formatted like:"
    , "                   filename.ext:20"
    , "                 If omitted, reads from stdin."
    , ""
    , "Options:"
    , "  -i, --ignore-case     Treat the pattern as case insensitive."
    , "  -s, --case-sensitive  Treat the pattern as case sensitive [default]."
    , "  -v, --invert-match    Print the location if there isn't a match there."
    , "  --version             Print version and exit."
    , ""
    , "[1]: http://www.smlnj.org/doc/smlnj-lib/Manual/parser-sig.html"
    ]

  fun failWithUsage msg =
    (eprintln $ msg;
     eprintln $ "";
     eprintln $ usage ();
     OS.Process.exit OS.Process.failure)

  datatype input
    = FromFile of string
    | FromStdin

  type requiredOptions =
    { pattern: string
    , input: input
    }

  type extraOptions =
    { invert: bool
    , caseSensitive: bool
    }

  type options =
    { pattern: string
    , input: input
    , invert: bool
    , caseSensitive: bool
    }

  fun withInvert {invert = _, caseSensitive} invert =
    {invert, caseSensitive}
  fun withCaseSensitive {invert, caseSensitive = _} caseSensitive =
    {invert, caseSensitive}

  fun withExtraOptions {pattern, input} {invert, caseSensitive} =
    { pattern
    , input
    , invert
    , caseSensitive
    }

  fun accumulateOptions argv acc =
    case argv
      of "--version"::_ =>
           (println version;
            OS.Process.exit OS.Process.success)
       | "-h"::_ =>
           (println $ usage ();
            OS.Process.exit OS.Process.success)
       | "--help"::_ =>
           (println $ usage ();
            OS.Process.exit OS.Process.success)
       | "-v"::argv' =>
           accumulateOptions argv' (withInvert acc true)
       | "--invert-match"::argv' =>
           accumulateOptions argv' (withInvert acc true)
       | "-i"::argv' =>
           accumulateOptions argv' (withCaseSensitive acc false)
       | "--ignore-case"::argv' =>
           accumulateOptions argv' (withCaseSensitive acc false)
       | "-s"::argv' =>
           accumulateOptions argv' (withCaseSensitive acc true)
       | "--case-sensitive"::argv' =>
           accumulateOptions argv' (withCaseSensitive acc true)
       | [] => failWithUsage "Missing required <pattern> argument."
       | [pattern] =>
           withExtraOptions {pattern = pattern, input = FromStdin} acc
       | [pattern, filename] =>
           withExtraOptions {pattern = pattern, input = FromFile filename} acc
       | arg0::_ => failWithUsage $ "Unrecognized argument: " ^ arg0

  val defaultOptions =
    { invert = false
    , caseSensitive = true
    }

  fun parseArgs argv = accumulateOptions argv defaultOptions

  end
end
