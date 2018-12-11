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

  type options =
    { pattern: string
    , input: input
    , invert: bool
    }

  fun withPattern {pattern = _, input, invert} pattern =
    {pattern = pattern, input = input, invert = invert}
  fun withInput {pattern, input = _, invert} input =
    {pattern = pattern, input = input, invert = invert}
  fun withInvert {pattern, input, invert = _} invert =
    {pattern = pattern, input = input, invert = invert}

  fun parseArgs argv =
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
           withInvert (parseArgs argv') true
       | "--invert-match"::argv' =>
           withInvert (parseArgs argv') true
       | [] => failWithUsage "Missing required <pattern> argument."
       | [pattern] =>
           {pattern = pattern, input = FromStdin, invert = false}
       | [pattern, filename] =>
           {pattern = pattern, input = FromFile filename, invert = false}
       | arg0::_ => failWithUsage $ "Unrecognized argument: " ^ arg0

  end
end
