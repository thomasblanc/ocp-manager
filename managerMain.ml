open ManagerMisc
open ManagerInit

let something_done = ref false
let ok () = something_done := true

let force_arg = ref false

let arg_list = Arg.align [
  "-list", Arg.Unit (fun _ ->
    ManagerSwitch.list_switches ();
    ok ()), " List available switches";
  "-set", Arg.String (fun s ->
    ManagerSwitch.set_current_switch s;
    ok ()), "SWITCH Set current switch";
  "-dir", Arg.String (fun s ->
    ManagerSwitch.print_directory s;
    ok ()), "KIND Echo current directory for KIND (bin,lib,prefix)";
  "-config", Arg.Unit (fun _ ->
    ManagerConfig.arg_handler ();
    ok ()), " Shell config for using ocp-manager wrappers";

  "-tools", Arg.Unit (fun _ ->
    ManagerTools.print_commands ();
    ok ()), " List available ocaml tools";
  "-missing-tools", Arg.Unit (fun _ ->
    ManagerTools.print_missing ();
    ok ()), " List missing tools";
  "-add-tool", Arg.String (fun s ->
    ManagerTools.add_command s;
    ok ()), "CMD Manage this command from now on";
  "-remove-tool", Arg.String (fun s ->
    ManagerTools.remove_command s;
    ok ()), "CMD Remove this command from managed tools";
  "-add-all", Arg.Unit (fun s ->
    ManagerTools.add_all_commands ();
    ok ()), " Manage all commands from the switch from now on";

  "-add-default", Arg.String (fun s ->
    ManagerTools.add_default_command s;
    ok ()), "CMD Set this executable as the default for this command";
  "-remove-default", Arg.String (fun s ->
    ManagerTools.remove_default s;
    ok ()), "CMD Remove this command from default";


  "-compile", Arg.String (fun s ->
    ManagerCompile.arg_handler s !force_arg;
    ok ()), "SWITCH Compile ocaml distribution in current directory as SWITCH";

  "-restore", Arg.Unit (fun _ ->
    ManagerRestore.arg_handler ();
    ok ()), " Restore computer distribution";

  "-force-update", Arg.Unit (fun _ ->
    ManagerInit.auto_update ();
    ok ()), " Force auto-update with this binary";

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
