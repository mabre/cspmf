#!/bin/bash

source ../make.config.sh

mkdir build 2> /dev/null

echo $bold*** Compiling Parsec ***$normal
$fregec -d build -make src/Text/ParserCombinators/Parsec/Pos.fr src/Text/ParserCombinators/Parsec/Error.fr src/Text/ParserCombinators/Parsec/Prim.fr src/Text/ParserCombinators/Parsec/Char.fr src/Text/ParserCombinators/Parsec/Combinator.fr src/Text/ParserCombinators/Parsec/Expr.fr src/Text/ParserCombinators/Parsec/Parsec.fr src/Text/ParserCombinators/Parsec/Token.fr src/Text/ParserCombinators/Parsec/Language.fr
success fregec $?

echo $bold*** Compiling Scrap Your Boilerplate ***$normal
$javac -d build/ src/com/netflix/frege/runtime/Fingerprint.java
success javac $?
$fregec -d build -make src/Data/Typeable.fr src/Data/Fingerprint.fr src/Data/Typeable.fr src/Data/Data.fr src/Data/Generics/Aliases.fr src/Data/Generics/Schemes.fr src/Data/Generics/Builders.fr
success fregec $?

echo $bold*** Compiling everything else ***$normal
$fregec -d build -make src/Text/PrettyPrint.fr src/System/FilePath.fr src/Data/Map.fr src/Data/IntMap.fr src/Data/Set.fr src/Data/Version.fr
success fregec $?
