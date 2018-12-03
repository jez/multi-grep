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

    val prev_filename = ref NONE
    val next_lineno = ref 1
    val open_file = ref NONE
  in
    forLine input_file (fn (i, input_line) => let
      val [filename, lineno_str] =  String.tokens tokenizer input_line
      val SOME lineno = Int.fromString lineno_str

      val file =
        case !open_file
          of NONE => TextIO.openIn filename
           | SOME f =>
               if !prev_filename <> SOME filename
               then
                 (next_lineno := 1;
                  TextIO.closeIn f;
                  TextIO.openIn filename)
               else
                 f
      val _ = prev_filename := SOME filename
      val _ = open_file := SOME file
    in
      (forLine file (fn (j, line) => let
        val check_this_line = !next_lineno = lineno
        val _ = next_lineno := !next_lineno + 1
      in
        if check_this_line
        then
           ((case find re line
              of NONE => ()
               | SOME _ => println $ filename^":"^lineno_str);
            raise Break)
        else ()
      end)) handle Break => ()
    end);
    OS.Process.success
  end
end
