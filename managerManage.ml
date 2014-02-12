open ManagerMisc
open ManagerInit


let arg_handler () =
  if Sys.file_exists distrib_dir then begin
    Printf.fprintf stderr "ocp-manager is supposed to be in control\n%!";
    Printf.fprintf stderr "\told binaries here: %s\n%!" distrib_dir;
    exit 2;
  end;
  MinUnix.mkdir distrib_dir 0o755;
  let binaries = load_binaries () in
  List.iter manage_binary binaries
