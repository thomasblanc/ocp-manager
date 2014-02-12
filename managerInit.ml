(*
  We need several parameters:
  - the directory where the binaries should be installed (we might need to be root
    or admin to manage this directory)
  - the directory where the distributions are installed


*)


open ManagerMisc

let install_prefix = "/usr/"
let libdir = Filename.concat install_prefix "lib/ocp-manager"
let bindir = Filename.concat install_prefix "bin"
let distrib_dir = Filename.concat libdir "distrib"

let basename = Filename.basename Sys.argv.(0)

let list_of_binaries_filename = Filename.concat libdir "binaries.txt"
let manager_binary_filename = Filename.concat libdir basename

let homedir = Sys.getenv "HOME"

let force_arg = ref false

type compiler_kind =
  DISTRIBUTION
| OCAML_MANAGER of string
| OPAM_COMPILER of string * string


type compiler = {
  compiler_name : string;
  compiler_kind : compiler_kind;
  compiler_prefix : string;
}

let compilers = Hashtbl.create 133
let compilers_list = ref []

let add_compiler c =
  Hashtbl.add compilers c.compiler_name c;
  compilers_list := c :: !compilers_list;
  match c.compiler_kind with
    DISTRIBUTION
  | OCAML_MANAGER _ -> ()
  | OPAM_COMPILER (comp, alias) ->
    if not (Hashtbl.mem compilers alias) then
        Hashtbl.add compilers alias c

let manager_roots_dir = Filename.concat homedir ".ocaml/roots"

let read_compilers () =

  if Sys.file_exists (Filename.concat distrib_dir "ocamlc") then
    add_compiler {
      compiler_name = "distrib";
      compiler_kind = DISTRIBUTION;
      compiler_prefix = distrib_dir; (* not a prefix ! *)
    };

  List.iter (fun dir ->
      let prefix = Filename.concat manager_roots_dir dir in
      if Sys.file_exists (Filename.concat prefix "bin/ocamlc") then
        add_compiler {
          compiler_name = dir;
          compiler_prefix = prefix;
          compiler_kind = OCAML_MANAGER dir;
        }
    )
    (list_directory manager_roots_dir);

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


let current_filename = Filename.concat homedir ".ocaml/current.txt"

let pwd = Unix.getcwd ()
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

let compiler_bindir c =
  match c.compiler_kind with
    DISTRIBUTION ->
      distrib_dir
  | OPAM_COMPILER _ | OCAML_MANAGER _ ->
    Filename.concat c.compiler_prefix "bin"

let compiler_prefix c =
    match c.compiler_kind with
      DISTRIBUTION ->
        Printf.fprintf stderr "Error: doesn't know prefix for distrib\n%!";
        exit 2
    | OPAM_COMPILER _
    | OCAML_MANAGER _
      -> c.compiler_prefix

let compiler_libdir c =
  let prefix_dir = compiler_prefix c in
  match c.compiler_kind with
    DISTRIBUTION -> assert false
  | OPAM_COMPILER _ ->
    Filename.concat prefix_dir "lib"
  | OCAML_MANAGER _ ->
    Filename.concat prefix_dir "lib/ocaml"

let get_current_compiler_opt () =
  try
    Some (Hashtbl.find compilers current_version)
  with Not_found -> None

let get_current_compiler () =
  match get_current_compiler_opt () with
    Some c -> c
  | None ->
    Printf.fprintf stderr "Error: could not find current version %S"
      current_version;
    exit 2

let _ =
  if basename <> "ocp-manager" &&
    basename <> "ocp-manager"
  then
    let c = get_current_compiler () in
    let dirname = compiler_bindir c in
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
	    MinUnix.putenv "CAML_LD_LIBRARY_PATH" (Filename.concat libdir "stublibs")
	| _ -> ()
    end;
    if Sys.file_exists filename then begin
      Sys.argv.(0) <- filename;
	(try MinUnix.execv Sys.argv.(0) argv with
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
        let exec_name = Filename.concat (compiler_bindir c) basename in
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


let load_binaries () =
  ManagerMisc.lines_of_file list_of_binaries_filename

let save_binaries binaries =
  let oc = open_out list_of_binaries_filename in
  List.iter (fun s -> Printf.fprintf oc "%s\n" s) binaries;
  close_out oc


let manage_binary binary =
  let binary_filename = Filename.concat bindir binary in
  if Sys.file_exists binary_filename then begin
    Printf.fprintf stderr "Saving executable %s to %s\n%!"
      binary_filename (Filename.concat distrib_dir binary);
    Sys.rename binary_filename (Filename.concat distrib_dir binary);
  end;

  if not (Sys.file_exists binary_filename) then begin
    Printf.fprintf stderr "Creating stub executable %s\n%!" binary_filename;
    OnlyUnix.symlink "ocp-manager" binary_filename;
  end;
  Printf.fprintf stderr "%s is now managed\n%!" binary
