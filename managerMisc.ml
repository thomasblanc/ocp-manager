module MinUnix = Unix
module OnlyUnix = Unix

let before s pos = String.sub s 0 pos
let after s pos =
  let len = String.length s in
  String.sub s pos (len - pos)

let cut_at s c =
    try
      let pos = String.index s c in
	before s pos,
      after s (pos+1);
    with _ -> s, ""

let is_directory filename =
  (MinUnix.lstat filename).MinUnix.st_kind = MinUnix.S_DIR


let list_directory dirname =
  let list = ref [] in
  let dir = OnlyUnix.opendir dirname in
    try
      while true do
	let file = OnlyUnix.readdir dir in
	  if file <> "." && file <> ".." then
	list := file :: !list
      done;
      assert false
    with End_of_file ->
      OnlyUnix.closedir dir;
      List.sort compare !list

let lines_of_file filename =
  let lines = ref [] in
  let ic = open_in filename in
  begin
    try
      while true do
	lines := input_line ic :: !lines
      done
    with _ -> ()
  end;
  close_in ic;
  List.rev !lines

let buf_size = 32764
let buf = String.create buf_size

let copy src dst = (* copy_file *)
  let src = open_in_bin src in
  let dst = open_out_bin dst in
  let rec iter () =
    let nread = input src buf 0 buf_size in
    if nread > 0 then begin
        output dst buf 0 nread;
        iter ()
      end

  in
  iter ();
  close_in src;
  close_out dst

