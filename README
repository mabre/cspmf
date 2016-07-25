# cspmf

[![Build Status](https://travis-ci.org/mabre/cspmf.svg?branch=master)](https://travis-ci.org/mabre/cspmf)

CSP-M is the machine readable syntax of CSP (concurrent sequential processes) as
used by the formal methods tools FDR, Probe and ProB.

CSPM-Frontend contains functions for lexing, parsing, renaming and pretty-
printing CSP-M specifications. The parser is (almost) 100% compatible with the
FDR-2.91 parser.

CSPM-ToProlog contains a translation from a CSPM AST to the representation used
by the [ProB](https://www3.hhu.de/stups/prob/index.php/Main_Page) tool. This
code is only interesting for ProB developers.

CSPM-cspm-frontend contains the code for cspmf, a small command line tool for
parsing CSPM specifications. It supports serveral modes of parsing.

```
# print a help message
./cspmf.sh --help
# parse spec and translate the AST to a prolog file (case used by the ProB-Tool).
./cspmf.sh translate spec.csp --prologOut=destination
```

## Compiling cspmf

First make sure that all paths and command in the Makefile match your system.
[Frege](https://github.com/Frege/frege/releases) is required in version
3.23.422-ga05a487.

```
make dist
```
