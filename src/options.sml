structure Options =
struct
  local
    open Prelude
    infixr 0 $
  in

  val version = "0.2.0"

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
    {invert = invert, caseSensitive = caseSensitive}
  fun withCaseSensitive {invert, caseSensitive = _} caseSensitive =
    {invert = invert, caseSensitive = caseSensitive}

  fun withExtraOptions {pattern, input} {invert, caseSensitive} =
    { pattern = pattern
    , input = input
    , invert = invert
    , caseSensitive = caseSensitive
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
