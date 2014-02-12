open ManagerMisc
open ManagerInit

let arg_handler binary =

  let binaries = load_binaries () in
  if List.mem binary binaries then begin
    Printf.fprintf stderr "%s already managed\n%!" binary; exit 2
  end;

  let oc = open_out list_of_binaries_filename in
  List.iter (fun tool ->
    Printf.fprintf oc "%s\n" tool) binaries;
  Printf.fprintf oc "%s\n" binary;
  close_out oc;

  manage_binary binary


