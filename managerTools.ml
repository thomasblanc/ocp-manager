open ManagerMisc
open ManagerInit

let arg_handler () =
  let c = get_current_compiler () in
  Printf.printf "Available tools in %s:\n" c.compiler_name;
  let binaries = ManagerMisc.lines_of_file list_of_binaries_filename in
  let managed_binaries = ref StringMap.empty in
  List.iter (fun tool ->
    managed_binaries := StringMap.add tool (ref false) !managed_binaries)
    binaries;
  List.iter (fun line ->
    Printf.printf "\t%s%s\n" line
      (try
         let ref = StringMap.find line !managed_binaries in
         ref := true;
         ""
       with Not_found -> " (not managed)")
  ) (list_directory (compiler_bindir c));

  let unavailable = ref [] in
  StringMap.iter (fun tool ref ->
    if not !ref then unavailable := tool :: !unavailable
  ) !managed_binaries;
  Printf.printf "\n%d managed tools not available\n"
    (List.length !unavailable);
  List.iter (fun line ->
    Printf.printf "\t%s\n" line) !unavailable;
  Printf.printf "%!"


