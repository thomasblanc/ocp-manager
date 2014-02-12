open ManagerMisc
open ManagerInit

let rec safe_mkdir dirname =
  if not (Sys.file_exists dirname) then begin
    safe_mkdir (Filename.dirname dirname);
    MinUnix.mkdir dirname 0o755;
  end

let arg_handler () =
  safe_mkdir libdir;
  ManagerMisc.copy "binaries.txt"  list_of_binaries_filename;
  let binfile = Filename.concat bindir "ocp-manager" in
  (try Sys.remove binfile with _ -> ());
  ManagerMisc.copy Sys.argv.(0) binfile;
  MinUnix.chmod binfile 0o755;
  Printf.printf "ocp-manager installed\n%!";
