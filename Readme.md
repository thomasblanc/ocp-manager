# ocp-manager

ocp-manager is a tool to manage several versions of OCaml on the same
computer.

## Compilation

You need 'ocp-build' installed on your computer:

    opam install ocp-build

Now, you can compile `ocp-manager`:

    ocp-build init
    ocp-build ocp-manager

## Requirements

- default ocaml binaries should be in /usr/bin/

## Installation

- Create your directory ~/.ocaml/roots:

     mkdir -p ~/.ocaml/roots

- In the directory containing a copy of "ocp-manager" and of
 "binaries.txt" (the list of tools managed by ocp-manager), call:

     sudo ocp-manager -install

  This will copy ocp-manager as /usr/bin/ocp-manager, and a directory
   /usr/lib/ocp-manager/.

- Now, call:

     sudo ocp-manager -manage

  This will move the files listed in binaries.txt into
   /usr/lib/ocp-manager/distrib/, and create links to /usr/bin/ocp-manager
   stubs at their place in /usr/bin/. Now, all the tools listed in
   binaries.txt are managed by ocp-manager.

## Usage

Use 'ocp-manager -list' to see the list of available versions.

To add a new version in the list, you just need to install a version of OCaml
in $HOME/.ocaml/roots/ocaml-$VERSION/{bin,lib,man}. You can use
'ocp-manager -compile SOME-VERSION' in the sources of OCaml to compile
and install a new version of OCaml, called SOME-VERSION in the list.

Use 'ocp-manager -set' to choose a new version. Note that this will switch
the global version of ocaml for your user, i.e. in all your terminals.

You can also set 'OCAML_VERSION' in your terminal to just change the
version of OCaml in this terminal.

Use 'ocp-manager -tools' to see available tools for the current version.
Use 'ocp-manager -add-binary TOOL' to add TOOL as a new managed tool.

## OPAM switches

`ocp-manager` can manage OPAM switches. Such switches should be
prefixed with "opam:". For example, you can use "opam:3.12.1" for OPAM
switch "3.12.1".

Be careful never to use `opam config env`, as this command will
override the PATH variable and prevent `ocp-manager` from working.

## Per-directory configuration

With `ocp-manager`, you can define a per-project switch: at the root
of your project, create a file '.ocp-switch' containing the switch
name, or '.opam-switch' containing the OPAM switch name.

For example, in a project `typerex`, I can have `.ocp-switch`
containing `opam:4.01.0`, or `.opam-switch` containing `4.01.0`, so
that, whatever the configuration of OPAM and `ocp-manager`, I will
always use 4.01.0 to compile this project.



