structure Main (*: MAIN*) =
struct
  local
    open Prelude
    infixr 0 $

    open Util
  in

  (* Input lines look like
   *
   *   file.txt:20
   *
   * and since they're coming from TextIO.inputLine, they're guaranteed to have
   * a trailing newline.
   *)
  fun parseInputLine inputLine =
    let
      fun colonOrNewline c = c = #":" orelse c = #"\n" orelse c = #"\r"
      val [filename, linenoStr] = String.tokens colonOrNewline inputLine
      val SOME lineno = Int.fromString linenoStr
    in
      (filename, lineno)
    end
    handle Bind =>
      (eprintln $ "Couldn't parse input line: "^inputLine;
       OS.Process.exit OS.Process.failure)

  fun main (arg0, argv) = let
    val {pattern = inputPattern, input, invert, caseSensitive} = Options.parseArgs argv

    val inputPattern =
      if caseSensitive
      then inputPattern
      else String.map Char.toLower inputPattern

    val re = RE.compileString inputPattern

    val inputFile =
      case input
        of Options.FromStdin => TextIO.stdIn
         | Options.FromFile inputFilename => TextIO.openIn inputFilename
    val inputFileStream = streamFromFile inputFile

    (* We keep three pieces of state, to avoid reopening files and rereading
     * lines that we've already seen. *)
    val openFilename = ref NONE
    val openFile = ref NONE
    val currLineno = ref 0

    fun processLine inputLine = let
      val (filename, lineno) = parseInputLine inputLine

      (* We go through great effort to reuse a file that's already open. *)
      val file =
        case !openFile
          of NONE => TextIO.openIn filename
           | SOME f =>
               if !openFilename <> SOME filename then
                 (currLineno := 0;
                  switchFile {old = f, new = filename})
               else if !currLineno < lineno then
                 f
               else
                 (* Close and reopen the same file to reset the stream. *)
                 (eprintln $ "warning: lines for "^filename^" do not strictly increase";
                  switchFile {old = f, new = filename})

      val fileStream = streamFromFile file
      do openFilename := SOME filename
      do openFile := SOME file

      exception Break
      fun checkForMatch line =
        ( currLineno := !currLineno + 1
        ; if !currLineno = lineno then
            let
              val line' =
                if caseSensitive
                then line
                else String.map Char.toLower line
            in
              (* Using <> to simulate XOR. *)
              ( if containsMatch re line' <> invert
                then println $ filename^":"^(Int.toString lineno)
                else ()
              ; raise Break
              )
            end
          else ()
        )

      do Stream.app checkForMatch fileStream handle Break => ()
    in () end

    do Stream.app processLine inputFileStream
  in
    OS.Process.success
  end
  end
end
