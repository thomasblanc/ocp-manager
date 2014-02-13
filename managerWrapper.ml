(*
Two modes:
* System mode: ocp-manager takes control over /usr/bin/ocaml* files.
    Any modification to these files require "sudoers" rights.

    # ocp-manager -manage-dir /usr/bin/
    # ocp-manager -restore-dir /usr/bin/
    # ocp-manager -manage-file /usr/bin/menhir
    # ocp-manager -restore-file /usr/bin/menhir
    # ocp-manager -restore-all
    # ocp-manager -manage-all

* User mode: ocp-manager takes control over ~/.ocp/manager-bin/ files
    Modifications do not require "sudoers" rights.

    $ ocp-manager -config
    PATH=".../.ocp/manager-bin/:$PATH"; export PATH

*)


open ManagerMisc

type compiler_kind =
  DISTRIBUTION
| OCAML_MANAGER of string
| OPAM_COMPILER of string * string


type compiler = {
  compiler_name : string;
  compiler_kind : compiler_kind;
  compiler_prefix : string;
}


let basename = Filename.basename Sys.argv.(0)

let homedir = Sys.getenv "HOME"
let path = Sys.getenv "PATH"

let ocpdir = Filename.concat homedir ".ocp"
let manager_bindir = Printf.sprintf "%s/.ocp/manager-bin" homedir
let path_sep = match Sys.os_type with
  | "win32" -> ';'
  | _ -> ':'

let old_manager_roots_dir = Filename.concat homedir ".ocaml/roots"
let manager_roots_dir = Filename.concat homedir ".ocp/manager-switches"

let compilers = ref StringMap.empty
let compilers_list = ref []

let add_compiler c =
  compilers := StringMap.add c.compiler_name c !compilers;
  compilers_list := c :: !compilers_list;
  match c.compiler_kind with
    DISTRIBUTION
  | OCAML_MANAGER _ -> ()
  | OPAM_COMPILER (comp, alias) ->
    if not (StringMap.mem alias !compilers) then
        compilers := StringMap.add alias c !compilers

let read_compilers () =

  (*  if Sys.file_exists (Filename.concat distrib_dir "ocamlc") then *)
  add_compiler {
    compiler_name = "distrib";
    compiler_kind = DISTRIBUTION;
    compiler_prefix = "";
  };

  List.iter (fun manager_roots_dir ->
    List.iter (fun dir ->
      let prefix = Filename.concat manager_roots_dir dir in
      if Sys.file_exists (Filename.concat prefix "bin/ocamlc") then
        add_compiler {
          compiler_name = dir;
          compiler_prefix = prefix;
          compiler_kind = OCAML_MANAGER dir;
        }
    )
      (try
        list_directory manager_roots_dir
      with _ -> [])
  ) [ old_manager_roots_dir; manager_roots_dir ];

  let opam_dir = Filename.concat homedir ".opam/" in
  let comps =
    try
      FileLines.of_file (Filename.concat opam_dir "aliases")
    with _ -> []
  in
  List.iter (fun line ->
    let (comp, alias) = OcpString.cut_at line ' ' in
    if comp <> "" && alias <> "" then
      add_compiler {
        compiler_name = "opam:" ^ alias;
        compiler_kind = OPAM_COMPILER (comp, alias);
        compiler_prefix = Filename.concat opam_dir alias;
      }
  ) comps

let _ = read_compilers ()
let compilers_list = !compilers_list
let compilers = !compilers


let current_filename = Filename.concat homedir ".ocaml/current.txt"

let pwd = Sys.getcwd ()
let find_up version_files =
  let rec iter dirname files =
    match files with
    | [] ->
      let new_dirname = Filename.dirname dirname in
      if new_dirname = dirname then None else
        iter new_dirname version_files
    | (version_file, prefix) :: next_files ->
      let filename = Filename.concat dirname version_file in
      match
        if Sys.file_exists filename then
          match File.lines_of_file filename with
            version :: _ -> Some (prefix ^ version)
          | _ -> None
        else None
      with None -> iter dirname next_files
         | Some _ as v -> v
  in
  try
    iter pwd version_files
  with e ->
    Printf.eprintf "ocp-manager: Warning, exception %S while looking for per-project files\n%!"
      (Printexc.to_string e);
    None

let current_version =
  try
    Sys.getenv "OCAML_VERSION"
  with Not_found ->
    match
      find_up [".ocp-switch", ""; ".opam-switch", "opam:" ]
    with Some version -> version
       | None ->
         try
           let ic = open_in current_filename in
           try
             let line = input_line ic in
             close_in ic;
             line
           with _ ->
             close_in ic;
             "distrib"
         with _ -> "distrib"


let compiler_bindir c basename =
  match c.compiler_kind with
  | DISTRIBUTION ->
    let path = OcpString.split path path_sep in
    let rec iter path =
      match path with
        [] -> "/usr/bin"
      | bindir :: next_path ->
        if bindir = manager_bindir then
          iter next_path
        else
        if Sys.file_exists (Filename.concat bindir basename) then
          bindir
        else
          iter next_path
    in
    iter path
  | OPAM_COMPILER _ | OCAML_MANAGER _ ->
    Filename.concat c.compiler_prefix "bin"

let compiler_prefix c =
    match c.compiler_kind with
      DISTRIBUTION -> Filename.dirname (compiler_bindir c "ocamlc")
    | OPAM_COMPILER _
    | OCAML_MANAGER _
      -> c.compiler_prefix

let compiler_libdir c =
  let prefix_dir = compiler_prefix c in
  match c.compiler_kind with
    DISTRIBUTION ->
    (* TODO: call "ocamlc -where" ! *)
    assert false
  | OPAM_COMPILER _ ->
    Filename.concat prefix_dir "lib"
  | OCAML_MANAGER _ ->
    Filename.concat prefix_dir "lib/ocaml"

let get_current_compiler_opt () =
  try
    Some (StringMap.find current_version compilers)
  with Not_found -> None

let get_current_compiler () =
  match get_current_compiler_opt () with
    Some c -> c
  | None ->
    Printf.fprintf stderr "Error: could not find current version %S"
      current_version;
    exit 2

let _ =
  if not (OcpString.starts_with basename "ocp-manager") then
    let c = get_current_compiler () in
    let dirname = compiler_bindir c basename in
    let filename = Filename.concat dirname basename in
    let argv = Sys.argv in
    let nargs = Array.length argv in
    let libdir = compiler_libdir c in
    let argv =
      if basename = "ocaml" then
        match c.compiler_kind with
          OPAM_COMPILER (_, alias) ->
            Array.concat [
              [| argv.(0) |];
              [| "-I"; Filename.concat libdir "toplevel" |];
              Array.sub argv 1 (nargs - 1)
            ]
        | _ -> argv
          else argv
    in
    begin
      match c.compiler_kind with
          OPAM_COMPILER _ ->
	    putenv "CAML_LD_LIBRARY_PATH" (Filename.concat libdir "stublibs")
	| _ -> ()
    end;
    if Sys.file_exists filename then begin
      Sys.argv.(0) <- filename;
	(try execv Sys.argv.(0) argv with
            e ->
	      Printf.fprintf stderr "Error \"%s\" executing %s\n%!"
                (Printexc.to_string e) Sys.argv.(0);
              exit 2
        )
    end else begin
      Printf.fprintf stderr "Error: %s does not exist\n%!" filename;
      let alternatives = compilers_list in
      let versions = ref [] in
      List.iter (fun c ->
        let exec_name = Filename.concat (compiler_bindir c basename) basename in
        if Sys.file_exists exec_name then
          versions := c :: !versions) alternatives;
      let versions = List.sort compare !versions in
      if versions = [] then
        Printf.fprintf stderr "This executable is not available in any version\n%!"
      else begin
        Printf.fprintf stderr "This executable is only available in the following versions:\n";
        List.iter (fun c -> Printf.fprintf stderr " %s" c.compiler_name) versions;
        Printf.fprintf stderr "\n%!";
      end;
      exit 2
    end
