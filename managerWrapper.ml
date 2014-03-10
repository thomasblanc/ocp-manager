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

(*
let environ = ref StringMap.empty

let _ =
  Array.iter (fun s ->
      let (var, _) = OcpString.cut_at s '=' in
      environ := StringMap.add var s !environ
    ) (Unix.environment ())

let putenv var v =
  environ := StringMap.add var (Printf.sprintf "%s=%s" var v) !environ
*)

let homedir = Sys.getenv "HOME"
let path = Sys.getenv "PATH"

let ocpdir = Filename.concat homedir ".ocp"
let manager_bindir = Printf.sprintf "%s/.ocp/manager-bin" homedir
let path_sep = match Sys.os_type with
  | "win32" -> ';'
  | _ -> ':'

let old_manager_roots_dir = Filename.concat homedir ".ocaml/roots"
let manager_roots_dir = Filename.concat ocpdir "manager-switches"
let manager_defaults = Filename.concat ocpdir "manager-defaults"

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


let current_filename = Filename.concat ocpdir "manager-current.txt"
let distrib_filename = Filename.concat ocpdir "manager-distrib.txt"

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
          prefix filename
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

let get_version_of_file prefix filename =
  match File.lines_of_file filename with
    version :: _ -> Some (prefix ^ version)
  | _ -> None

let current_version =
  try
    Sys.getenv "OCAML_VERSION"
  with Not_found ->
    match
      find_up [".ocp-switch", get_version_of_file "";
               ".opam-switch", get_version_of_file "opam:" ]
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

let find_bindir exe =
  let path = OcpString.split path path_sep in
  let rec iter path =
    match path with
      [] -> None
    | bindir :: next_path ->
      if bindir = manager_bindir then
        iter next_path
      else
      if Sys.file_exists (Filename.concat bindir exe) then
        Some bindir
      else
        iter next_path
  in
  iter path

let compiler_bindir c =
  match c.compiler_kind with
  | DISTRIBUTION -> begin match find_bindir "ocamlc" with
        None -> "/usr/bin"
      | Some bindir -> bindir
    end
  | OPAM_COMPILER _ | OCAML_MANAGER _ ->
    Filename.concat c.compiler_prefix "bin"

let compiler_prefix c =
    match c.compiler_kind with
      DISTRIBUTION -> Filename.dirname (compiler_bindir c)
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

let basename = Filename.basename Sys.argv.(0)
let is_ocpmanager =
  OcpString.starts_with basename "ocp-manager"

let is_exec =
  let nargs = Array.length Sys.argv in
  if is_ocpmanager then
    if nargs > 2 && Sys.argv.(1) = "-exec" then
      Some (Array.sub Sys.argv 2 (nargs - 2))
    else None
  else Some Sys.argv

let _ =
  match is_exec with
  | None -> ()
  | Some argv ->
    let c = get_current_compiler () in
    let nargs = Array.length argv in
    let basename = Filename.basename argv.(0) in
    let argv =
      if basename = "ocaml" then
        match c.compiler_kind with
          OPAM_COMPILER (_, alias) ->
          let libdir = compiler_libdir c in
          Array.concat [
            [| argv.(0) |];
            [| "-I"; Filename.concat libdir "toplevel" |];
            Array.sub argv 1 (nargs - 1)
          ]
        | _ -> argv
      else argv
    in
    let dirname = compiler_bindir c in
    let filename =
      let filename = Filename.concat dirname basename in
      if Sys.file_exists filename then filename else
        match
          match c.compiler_kind with
            OPAM_COMPILER ("system", _) ->
            begin match find_bindir "ocamlc" with
              | None -> None
              | Some dirname ->
                let filename = Filename.concat dirname basename in
                if Sys.file_exists filename then Some filename else None
            end
          | _ -> None
        with
        | Some filename -> filename
        | None ->
          let filename = Filename.concat manager_defaults basename in
          if Sys.file_exists filename then filename else
            match
              if is_ocpmanager then
                find_bindir basename
              else None
            with
            | Some bindir -> Filename.concat bindir basename
            | None ->
              begin
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
    in

    begin
      match c.compiler_kind with
      | OPAM_COMPILER _ ->
        let libdir = compiler_libdir c in
	putenv "CAML_LD_LIBRARY_PATH"
          (Printf.sprintf "%s/stublibs:%s/ocaml/stublibs" libdir libdir);
        let manpath = try Sys.getenv "MANPATH" with Not_found -> "" in
        putenv "MANPATH"
          (Printf.sprintf "%s/man:%s" c.compiler_prefix manpath);

      | _ -> ()
    end;

    (* Use ~/.ocp/manager-env.txt to add env variables to switch *)
    begin try
        File.iter_lines (fun line ->
            let (switch, line) = OcpString.cut_at line ' ' in
            let (var, value) = OcpString.cut_at line '=' in
            if switch = c.compiler_name || switch = "*" then
              putenv var value
          ) (Filename.concat ocpdir "manager-env.txt")
      with _ -> ()
    end;

    (* Use .ocp-env files to add env variables to switch *)
    let env = ref [] in
    let store_env filename = env := filename :: !env; None in
    ignore (find_up [ ".ocp-env", store_env ] = None);
    List.iter (fun filename ->
        try
          File.iter_lines (fun line ->
              let (switch, line) = OcpString.cut_at line ' ' in
              let (var, value) = OcpString.cut_at line '=' in
              if switch = c.compiler_name || switch = "*" then
                putenv var value
            ) filename
        with _ -> ()
      ) !env;

(*
    let get_env () =
      let list = ref [] in
      StringMap.iter (fun var s ->
          list := s :: !list;
          Printf.eprintf "env %S\n%!" s;
        ) !environ;
      Array.of_list !list
    in
*)
    argv.(0) <- filename;
    (try execv argv.(0) argv with
       e ->
       Printf.fprintf stderr "Error \"%s\" executing %s\n%!"
         (Printexc.to_string e) argv.(0);
       exit 2
    )
