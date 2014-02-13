open ManagerMisc
open ManagerInit

let something_done = ref false
let ok () = something_done := true

let force_arg = ref false

let arg_list = [
  "-list", Arg.Unit (fun _ ->
    ManagerList.arg_handler ();
    ok ()), " : list available switches";
  "-set", Arg.String (fun s ->
    ManagerSet.arg_handler s;
    ok ()), " <name> : set current switch";
  "-dir", Arg.String (fun s ->
    ManagerDirectory.arg_handler s;
    ok ()), " KIND : echo current directory for KIND (bin,lib,prefix)";
  "-config", Arg.Unit (fun _ ->
    ManagerConfig.arg_handler ();
    ok ()), " : shell config for using ocp-manager wrappers";

  "-tools", Arg.Unit (fun _ ->
    ManagerTools.arg_handler ();
    ok ()), " : list available ocaml tools";
  "-missing", Arg.Unit (fun _ ->
    ManagerMissing.arg_handler ();
    ok ()), " : list missing tools";
  "-compile", Arg.String (fun s ->
    ManagerCompile.arg_handler s !force_arg;
    ok ()), " <name> : compile ocaml distribution in current directory";
  "-add", Arg.String (fun s ->
    ManagerAddBinary.arg_handler s;
    ok ()), " <exec> : manage this executable from now on";

  "-restore", Arg.Unit (fun _ ->
    ManagerRestore.arg_handler ();
    ok ()), " : restore computer distribution";

(*
  "-install", Arg.Unit (fun _ ->
    ManagerInstall.arg_handler ();
    ok ()), " : install ocp-manager";
  "-manage", Arg.Unit (fun _ ->
    ManagerManage.arg_handler ();
    ok ()), " : take control over computer distribution";
  "-update", Arg.Unit (fun _ ->
    ManagerRestore.arg_handler ();
    ManagerManage.arg_handler ();
    ok ()), " : apply a new binaries list";
  "-add", Arg.String (fun s ->
    ManagerRestore.arg_handler ();
    let binaries = load_binaries () in
    let binaries = s :: binaries in
    save_binaries binaries;
    ManagerManage.arg_handler ();
    ok ()
  ), " <name> : add an executable to binaries";
*)

  "-f", Arg.Set force_arg, " force when possible";

]

let arg_usage = Printf.sprintf "%s [options] files" Sys.argv.(0)

let _ =
  try
    Arg.parse arg_list (fun s -> Arg.usage arg_list arg_usage) arg_usage;
    if not !something_done then
      Arg.usage arg_list arg_usage
    else
      flush stdout;
    if ManagerInit.first_install then begin
      Printf.eprintf "%s\n%!"
        (String.concat "\n" [
	   "";
    "Don't forget to update your configuration files with";
    "";
    "    eval `ocp-manager -config`";
	""])
    end

  with e ->
    Printf.fprintf stderr "Uncaught exception %s\nExiting\n%!" (Printexc.to_string e);
    exit 2
