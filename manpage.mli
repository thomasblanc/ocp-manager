
type man_block =
  | S of string
  | P of string
  | I of string * string
  | NOBLANK

type pager =
  | PLAIN
  | PAGER
  | GROFF

type 'div man_page = {
    man_name : string;   (* "OPAM" "GCC" *)
    man_section : int;
    man_date : string;
    man_release : string; (* "SOFT VERSION" *)
    man_org : string; (* GNU, OPAM Manual *)
    man_text : 'div list;
}

val print :
  ?subst:(string -> string) -> pager ->
  Format.formatter ->
  man_block man_page -> unit

module RAW : sig

  type div =
    | SH of span list
    | LI of span list * span list
    | P of span list
    | P2 of span list

  and span =
    | S of string
    | B of string
    | I of string

  val groff_page : div man_page -> string

end
