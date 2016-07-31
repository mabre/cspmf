# cspmf

[![Build Status](https://travis-ci.org/mabre/cspmf.svg?branch=frege)](https://travis-ci.org/mabre/cspmf)

CSP-M is the machine readable syntax of [CSP](https://en.wikipedia.org/wiki/Communicating_sequential_processes) (concurrent sequential processes) as
used by the formal methods tools [FDR](http://www.fsel.com/software.html), [ProBE](http://www.fsel.com/software.html) and [ProB](http://www.stups.uni-duesseldorf.de/ProB/).

CSPM-Frontend contains functions for lexing, parsing, renaming and
pretty-printing CSP-M specifications. The parser is (almost) 100% compatible
with the FDR-2.91 parser.

CSPM-ToProlog contains a translation from a CSPM AST to the representation used
by the [ProB](http://www.stups.uni-duesseldorf.de/ProB/) tool. This
code is only interesting for ProB developers.

CSPM-cspm-frontend contains the code for cspmf, a small command line tool for
parsing CSPM specifications. It supports serveral modes of parsing.

```bash
# print a help message
./cspmf.sh --help
# parse spec and translate the AST to a prolog file (case used by the ProB-Tool)
./cspmf.sh translate spec.csp --prologOut=destination
```

## Compiling cspmf

First make sure that all paths and command in the Makefile match your system.
[Frege](https://github.com/Frege/frege/releases) is required in version
3.23.422-ga05a487, [alex](https://hackage.haskell.org/package/alex) should be
installed in version 3.1.7 (`cabal install alex-3.1.7`).

```bash
make cspmf
make jar
```

The jar is compressed using [ProGuard](http://proguard.sourceforge.net). If you cannot or do not want to build the jar, you can also run cspmf from the build directory using `./cspmf.built.sh`.

Use `make test` to run the automatic tests.

To generate the documentation, run `make doc`.
