(*
 * This structure is for things which I would NOT want to open in every SML
 * project, but are nice to open in this project in particular.
 *
 * See also: src/prelude.sml
 *)
structure Util =
struct
  (* --- regexp utils ------------------------------------------------------ *)
  structure RE = RegExpFn(
    structure P = AwkSyntax
    (* DfaEngine currently does not support ^ or $ in regex. *)
    structure E = BackTrackEngine
  )

  fun containsMatch regex str =
    Option.isSome (StringCvt.scanString (RE.find regex) str)

  (* --- textio utils ------------------------------------------------------ *)
  fun switchFile {old = file, new = filename} =
    (TextIO.closeIn file; TextIO.openIn filename)

  (* --- cmlib utils ------------------------------------------------------- *)
  (*
   * We're making our own stream (instead of using Stream.fromTextInstream)
   * because we want to stream data line-wise, instead of character-wise.
   *)
  fun streamFromFile file =
    Stream.fromProcess (fn () => TextIO.inputLine file)


end
