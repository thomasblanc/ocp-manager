# ocaml-manager

ocaml-manager is a tool to manage several versions of OCaml on the same
computer.

## Requirements

- default ocaml binaries should be in /usr/bin/

## Installation

- In the directory containing a copy of "ocaml-manager" and of
 "binaries.txt" (the list of tools managed by ocaml-manager), call:

    sudo ocaml-manager -install

  This will copy ocaml-manager as /usr/bin/ocaml-manager, and a directory
   /usr/lib/ocaml-manager/.

- Now, call:

    sudo ocaml-manager -manage

  This will move the files listed in binaries.txt into
   /usr/lib/ocaml-manager/distrib/, and create links to /usr/bin/ocaml-manager
   stubs at their place in /usr/bin/. Now, all the tools listed in
   binaries.txt are managed by ocaml-manager.

## Usage

Use 'ocaml-manager -list' to see the list of available versions.

To add a new version in the list, you just need to install a version of OCaml
in $HOME/.ocaml/roots/ocaml-$VERSION/{bin,lib,man}. You can use
'ocaml-manager -compile SOME-VERSION' in the sources of OCaml to compile
and install a new version of OCaml, called SOME-VERSION in the list.

Use 'ocaml-manager -set' to choose a new version. Note that this will switch
the global version of ocaml for your user, i.e. in all your terminals.

You can also set 'OCAML_VERSION' in your terminal to just change the
version of OCaml in this terminal.

Use 'ocaml-manager -tools' to see available tools for the current version.
Use 'ocaml-manager -add-binary TOOL' to add TOOL as a new managed tool.

