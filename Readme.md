# ocp-manager

ocp-manager is a tool to manage several versions of OCaml on the same
computer.

## Compilation and Installation

You need 'ocp-build' installed on your computer:

    opam install ocp-build

Now, you can compile `ocp-manager`:

    ./configure
    make
    make install

You need to configure your PATH variable. You can add in your ~/bashrc (or
  whatever configure file for your shell):

    eval `ocp-manager -config`

## How to update

If you have a version of 'ocp-manager' before Feb 13. 2014, you should
restore what it might have changed:

   ocp-manager -restore

## Usage

Use 'ocp-manager -list' to see the list of available versions.

To add a new version in the list, you just need to install a version of OCaml
in $HOME/.ocp/manager-switches/ocaml-$VERSION/{bin,lib,man}. You can use
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



