structure Main : MAIN =
struct
  (* TODO(jez) Tweak these? *)
  structure RE = RegExpFn(
    structure P = AwkSyntax
    structure E = BackTrackEngine
  )

  fun println str = print (str ^ "\n")
  fun eprint str =
    (TextIO.output (TextIO.stdErr, str);
     TextIO.flushOut TextIO.stdErr)
  fun eprintln str = eprint (str ^ "\n")

  infixr 0 $
  fun f $ x = f x

  exception Break

  fun isColon c = c = #":"
  fun tokenizer c = isColon c orelse Char.isSpace c
  fun find regex str = StringCvt.scanString (RE.find regex) str

  fun forLine file f =
    let
      fun loop i =
        case TextIO.inputLine file
          of NONE => ()
           | SOME line =>
               (f (i, line);
                loop (i + 1))
    in
      loop 0
    end

  fun main (arg0, argv) = let
    val (input_filename, input_pattern) =
      case argv
        of [arg1, arg2] => (arg1, arg2)
         | _ =>
             (eprintln $ "usage: "^arg0^" <locs.txt> <pattern>";
              OS.Process.exit OS.Process.failure)

    val re = RE.compileString input_pattern

    val input_file = TextIO.openIn input_filename

  in
    forLine input_file (fn (i, input_line) => let
      val [filename, lineno_str] =  String.tokens tokenizer input_line
      val SOME lineno = Int.fromString lineno_str

      val file = TextIO.openIn filename
    in
      forLine file (fn (j, line) =>
        case Int.compare (j, lineno - 1)
          of LESS => ()
           | GREATER => raise Break
           | EQUAL =>
               case find re line
                 of NONE => ()
                  | SOME _ => println $ filename^":"^lineno_str
      ) handle Break => ()
    end);
    OS.Process.success
  end
end
