open ManagerMisc
open ManagerInit

let arg_handler s =
  let c = get_current_compiler () in
  Printf.printf "%s\n%!"
    (
      match s with
          "bin" -> compiler_bindir c
        | "prefix" -> compiler_prefix c
        | "lib" -> compiler_libdir c
        | _ -> failwith "bad dir kind"
    )



