open ManagerMisc
open ManagerInit

let arg_handler () =
  if not (Sys.file_exists distrib_dir) then begin
    Printf.fprintf stderr "ocp-manager not in control !l\n%!";
    exit 2;
  end;
  let binaries = ManagerMisc.lines_of_file list_of_binaries_filename in
  List.iter (fun binary ->
    let binary_filename = Filename.concat distrib_dir binary in
    let target_filename = Filename.concat bindir binary in

    begin
      try
	let st = MinUnix.lstat target_filename in
	match st.MinUnix.st_kind with
	    MinUnix.S_LNK ->
	            Printf.fprintf stderr "Removing stub executable %s\n%!" target_filename;
	      (try
		 Sys.remove target_filename
	       with e ->
		 Printf.fprintf stderr "\tError: %s\n%!" (Printexc.to_string e)
	      )
	  | _ -> ()
      with _ ->  ()
    end;

    if Sys.file_exists binary_filename then begin
      Printf.fprintf stderr "Restoring executable %s to %s\n%!"
	binary_filename target_filename;
      (try Sys.rename binary_filename target_filename with e ->
	Printf.fprintf stderr "\tError: %s\n%!" (Printexc.to_string e)
      );
    end
  ) binaries;
  MinUnix.rmdir distrib_dir;
