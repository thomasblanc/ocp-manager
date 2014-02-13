open ManagerMisc
open ManagerWrapper
open ManagerInit

let arg_handler version =
  try
    let c = StringMap.find version compilers in
    let oc = open_out current_filename in
    output_string oc c.compiler_name;
    output_char oc '\n';
    close_out oc;
    ManagerList.print_current_version "Old version";
    Printf.printf "New version: %s\n%!" version;
  with Not_found ->
    Printf.fprintf stderr "Error: no such alternative [%s]\n" version;
    Printf.fprintf stderr "\tuse -list to list alternatives\n%!";
    exit 2

