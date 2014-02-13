open ManagerMisc
open ManagerWrapper
open ManagerInit

let arg_handler basename =
  let filename = Filename.concat manager_bindir basename in
  if Sys.file_exists filename then
    Printf.eprintf "Warning: %S is already managed\n%!" basename
  else
    begin
      Printf.eprintf "Creating default wrapper for %S\n%!" basename;
      symlink "ocp-manager" filename;
    end
