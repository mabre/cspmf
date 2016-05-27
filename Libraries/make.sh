#!/bin/bash

build_dir="../build"

source ../make.config.sh

mkdir $build_dir 2> /dev/null

step "Compiling Parsec"
$fregec -d $build_dir -make src/Text/ParserCombinators/Parsec/Pos.fr src/Text/ParserCombinators/Parsec/Error.fr src/Text/ParserCombinators/Parsec/Prim.fr src/Text/ParserCombinators/Parsec/Char.fr src/Text/ParserCombinators/Parsec/Combinator.fr src/Text/ParserCombinators/Parsec/Expr.fr src/Text/ParserCombinators/Parsec/Parsec.fr src/Text/ParserCombinators/Parsec/Token.fr src/Text/ParserCombinators/Parsec/Language.fr
success fregec $?

step "Compiling Scrap Your Boilerplate"
$javac -d $build_dir src/com/netflix/frege/runtime/Fingerprint.java
success javac $?
$fregec -d $build_dir -make src/Data/Typeable.fr src/Data/Fingerprint.fr src/Data/Typeable.fr src/Data/Data.fr src/Data/Generics/Aliases.fr src/Data/Generics/Schemes.fr src/Data/Generics/Builders.fr
success fregec $?

step "Compiling everything else"
$fregec -d $build_dir -make src/Text/PrettyPrint.fr src/System/FilePath.fr src/Data/Map.fr src/Data/IntMap.fr src/Data/Set.fr src/Data/Version.fr src/Control/Monad/State.fr
success fregec $?
