structure Options =
struct
  local
    open Prelude
    infixr 0 $
  in

  fun usage () = String.concatWith "\n"
    [ "Usage:"
    , "  "^(CommandLine.name ())^" <pattern> [<locs.txt>]"
    , ""
    , "Options:"
    , "  <pattern>      An AWK-compatible[1] regular expression."
    , "  <locs.txt>     The name of a file with lines formatted like:"
    , "                   filename.ext:20"
    , "                 If omitted, reads from stdin."
    , ""
    , "Searches in the mentioned lines for the pattern and prints the lines"
    , "that contain a match."
    , ""
    , "[1]: http://www.smlnj.org/doc/smlnj-lib/Manual/parser-sig.html"
    ]

  fun failWithUsage msg =
    (eprintln $ msg;
     eprintln $ "";
     eprintln $ usage ();
     OS.Process.exit OS.Process.failure)

  datatype Input
    = FromFile of string
    | FromStdin

  fun parseArgs argv =
    case argv
      of [] => failWithUsage "Missing required <pattern> argument."
       | [pattern] => (pattern, FromStdin)
       | [pattern, filename] => (pattern, FromFile filename)
       | _ => failWithUsage "Too many arguments given."

  end
end
