open ManagerMisc
open ManagerInit

let arg_handler () =
  let alternatives = "distrib" :: list_directory roots_dir in
  Printf.printf "Current version: %s\n" current_version;
  Printf.printf "\tbinaries in %s\n" current_version_binaries;
  Printf.printf "Alternatives:\n";
  List.iter (fun line ->
	       Printf.printf "\t%s\n" line) alternatives;
  flush stdout
