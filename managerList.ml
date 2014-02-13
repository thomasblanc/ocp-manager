open ManagerMisc
open ManagerWrapper
open ManagerInit

let print_current_version msg =
  Printf.printf "Current version: %s\n" current_version;
  begin
    match get_current_compiler_opt () with
    | Some c ->
      Printf.printf "\tbinaries in %S\n" (compiler_bindir c "ocamlc")
    | None ->
      Printf.printf "\tWarning: could not find binaries of %S\n" current_version
  end

let arg_handler () =
  let alternatives = compilers_list in
  print_current_version "Current version";
  Printf.printf "Alternatives:\n";
  List.iter (fun c ->
    Printf.printf "\t%s\n" c.compiler_name) alternatives;

