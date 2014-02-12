open ManagerMisc
open ManagerInit

let arg_handler () =
  let binaries = ManagerMisc.lines_of_file list_of_binaries_filename in
  let c = get_current_compiler () in
  let bindir = compiler_bindir c in
  Printf.printf "Missing tools:\n";
  List.iter (fun binary ->
    if not (Sys.file_exists (Filename.concat bindir binary)) then
      Printf.printf "\t%s\n" binary
  ) binaries;
