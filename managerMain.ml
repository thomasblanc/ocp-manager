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


let get_arg arg_help default =
  let open Manpage.RAW in
  let (n, arg_help) = OcpString.cut_at arg_help ' ' in
  let n =
    if n = "" then
      default
    else
      n
  in
  [I n], arg_help

let groff_of_args arg_list =
  let open Manpage.RAW in
  List.map (fun (arg_name, arg_spec, arg_help) ->
    let (arg_spec, arg_help) = match arg_spec with
      | Arg.Int _ -> get_arg arg_help "INT"
      | Arg.String _ -> get_arg arg_help "STRING"
      | Arg.Unit _
      | _ -> ([], arg_help)
    in
    let arg_help = OcpString.skip_chars arg_help " \t" in
    LI (
      (B arg_name) :: (S " ") :: arg_spec
      ,
      [ S arg_help ]
    )
  ) arg_list

let _ =
  try
    Arg.parse (arg_list @
               [

                 "-h", Arg.Unit (fun () ->
                  let open Manpage in
                  print PAGER Format.err_formatter
                    {
                      man_name = "OCP-MANAGER";
                      man_section = 1;
                      man_date = "2014-02-14";
                      man_release = "ocp-manager 0.1";
                      man_org = "OCamlPro";
                      man_text = [
                        S "NAME";
                        P "ocp-manager ...";
                        S "SYNOPSIS";
                        P "ocp-manager "; I ("OPTIONS","OPTIONS");
                        S "DESCRIPTION";
                        P "ocp-manager is ...";
                        S "AUTHOR";
                        S "REPORTING BUGS";
                        S "COPYRIGHT";
                        S "SEE ALSO";
                      ]
                    };
                  exit 0
                ), " Print Help";

                 "-man", Arg.Unit (fun () ->
                  let open Manpage in
                  let open RAW in
                  Printf.printf "%s\n%!"
                    (groff_page
                    {
                      man_name = String.uppercase ManagerVersion.command;
                      man_section = 1;
                      man_date = ManagerVersion.release_date;
                      man_release = Printf.sprintf "%s %s"
                          ManagerVersion.command
                          ManagerVersion.version;
                      man_org = "OCamlPro";
                      man_text = [
                        SH [ S "NAME" ];
                        P [ S "ocp-manager ..." ];
                        SH [ S "SYNOPSIS" ];
                        P [ S "ocp-manager "; I "OPTIONS" ];

                        SH [ S "DESCRIPTION" ];
                        P [ S "ocp-manager is ..." ];

                        SH [ S "OPTIONS" ]
                      ] @
                                 groff_of_args arg_list

                                 @[

                        SH [ S "AUTHOR" ];
                        P [ S "Fabrice Le Fessant <Fabrice.Le_Fessant@inria.fr>" ];

                        SH [ S "BUGS" ];

                        SH [ S "COPYRIGHT" ];
                        P [ S "Copyright (c) 2011, 2012, 2013, 2014" ];
                        P [ S "INRIA & OCamlPro SAS." ];

                        SH [ S "SEE ALSO" ];
                        P [ B "opam"; S "(1)" ];
                      ]
                    };
                    );
                  exit 0;
                ), " Print Manpage";


               ])
      (fun s -> Arg.usage arg_list arg_usage) arg_usage;


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

  with
  | e ->
    Printf.fprintf stderr "Uncaught exception %s\nExiting\n%!" (Printexc.to_string e);
    exit 2
