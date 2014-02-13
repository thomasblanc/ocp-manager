open ManagerMisc
open ManagerWrapper
open ManagerInit

let arg_handler () =
  let binaries = Sys.readdir manager_bindir in
  let c = get_current_compiler () in
  let bindir = compiler_bindir c "ocamlc" in
  Printf.printf "Missing tools:\n";
  Array.iter (fun binary ->
    if binary <> "ocp-manager" &&
       not (Sys.file_exists (Filename.concat bindir binary)) then
      Printf.printf "\t%s\n" binary
  ) binaries;
