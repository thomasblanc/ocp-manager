open ManagerMisc
open ManagerInit


let arg_handler () =
  let new_path = Printf.sprintf "%s%c%s"
      ManagerWrapper.manager_bindir
      ManagerWrapper.path_sep
      ManagerWrapper.path in
  Printf.printf "PATH=%S; export PATH\n%!" new_path

