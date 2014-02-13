open ManagerMisc
open ManagerWrapper
open ManagerInit

let arg_handler () =
  let c = get_current_compiler () in
  Printf.printf "Available tools in %s:\n" c.compiler_name;
  let binaries = Sys.readdir manager_bindir in
  let managed_binaries = ref StringMap.empty in
  Array.iter (fun tool ->
    if tool <> "ocp-manager" then
      managed_binaries := StringMap.add tool (ref false) !managed_binaries)
    binaries;
  List.iter (fun line ->
    Printf.printf "\t%s%s\n" line
      (try
        let ref = StringMap.find line !managed_binaries in
        ref := true;
        ""
      with Not_found -> " (not managed)")
  ) (list_directory (compiler_bindir c "ocamlc"));

  let unavailable = ref [] in
  StringMap.iter (fun tool ref ->
    if not !ref then unavailable := tool :: !unavailable
  ) !managed_binaries;
  Printf.printf "\n%d managed tools not available\n"
    (List.length !unavailable);
  List.iter (fun line ->
    Printf.printf "\t%s\n" line) !unavailable;
  Printf.printf "%!"


