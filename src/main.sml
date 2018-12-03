structure Main : MAIN =
struct
  structure RE = RegExpFn(
    structure P = AwkSyntax
    structure E = DfaEngine
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

  fun usage arg0 =
    (eprintln $ "usage: "^arg0^" <locs.txt> <pattern>";
     OS.Process.exit OS.Process.failure)

  fun forLine file f =
    case TextIO.inputLine file
      of NONE => ()
       | SOME line => (f line; forLine file f)

  fun main (arg0, argv) = let
    val (inputFilename, inputPattern) =
      case argv
        of [arg1, arg2] => (arg1, arg2)
         | _ => usage arg0

    val re = RE.compileString inputPattern

    val inputFile = TextIO.openIn inputFilename

    val openFilename = ref NONE
    val openFile = ref NONE

    val currLineno = ref 0

    do forLine inputFile (fn inputLine => let
      val [filename, linenoStr] = String.tokens tokenizer inputLine
      val SOME lineno = Int.fromString linenoStr

      val file =
        case !openFile
          of NONE => TextIO.openIn filename
           | SOME f =>
               if !openFilename <> SOME filename
               then
                 (currLineno := 0;
                  TextIO.closeIn f;
                  TextIO.openIn filename)
               else
                 f
      do openFilename := SOME filename
      do openFile := SOME file

      do (forLine file (fn line => let
        do currLineno := !currLineno + 1
        do if !currLineno = lineno
           then
             ((case find re line
                 of NONE => ()
                  | SOME _ => println $ filename^":"^linenoStr);
              raise Break)
           else ()
      in () end)) handle Break => ()
    in () end)
  in
    OS.Process.success
  end
end
