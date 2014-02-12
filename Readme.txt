ocaml-manager:
==============

A simple program to manage multiple versions of ocaml on the same computer.

Installation
============

To install or update the current version of ocaml-manager
$ sudo ./ocaml-manager -install

To take control of the current distribution and save its binaries:
$ sudo ocaml-manager -manage

To restore the distribution binaries:
$ sudo ocaml-manager -restore

Usage
=====

To list available version of ocaml:
$ ocaml-manager -list

To choose among available versions:
$ ocaml-manager -set ocaml-XXX

To choose the distribtion version:
$ ocaml-manager -set distrib

To compile ocaml, install it and choose the new version
From within the sources:
$ ocaml-manager -compile ocaml-XXX

To list available tools:
$ ocaml-manager -tools

To list missing tools:
$ ocaml-manager -missing


