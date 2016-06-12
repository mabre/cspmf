BUILD       = build324
BUILD_TOOLS = Tools/build324
BUILD_DIRS  = $(BUILD) $(BUILD_TOOLS)

FREGEJAR = /home/markus/Downloads/frege/frege3.24.100.jar
ALEX     = /home/markus/.cabal/bin/alex
JAVAC    = javac -cp $(FREGEJAR):${BUILD}:Libraries/commons-cli-1.3.1.jar
JAVA     = java
MKDIR_P  = mkdir -p
RM       = rm -rf
BASH     = bash

FREGEC_ARGS = -hints -O
FREGEC0     = $(JAVA) -Xss16m -Xmx2g -jar $(FREGEJAR) -fp ${BUILD}:${BUILD_TOOLS}
FREGEC      = $(FREGEC0) $(FREGEC_ARGS)
FREGE       = $(JAVA) -Xss16m -Xmx2g -cp $(FREGEJAR):${BUILD}:${BUILD_TOOLS}


#dist: TODO copy *class, *jar to /dist, change *.sh, rm make.sh

cspmf: cspm-frontend cspm-toprolog cspm-cspm-frontend
	@echo "[1;42mMade $@[0m"

cspm-cspm-frontend: cspm-toprolog
	@echo "[1;42mMaking $@[0m"
	$(FREGEC) -d $(BUILD) -make -sp CSPM-cspm-frontend/src/Main \
		ExecCommand.fr \
		ExceptionHandler.fr
	
	$(JAVAC) -d $(BUILD) CSPM-cspm-frontend/src/Main/Main.java CSPM-cspm-frontend/src/Main/Benchmark.java

cspm-toprolog: cspm-frontend
	@echo "[1;42mMaking $@[0m"
	
	$(FREGEC) -d $(BUILD) -make -sp "CSPM-ToProlog/src/Language" \
		CSPM/CompileAstToProlog.fr \
		CSPM/TranslateTest.fr \
		CSPM/TranslateToProlog.fr \
		Prolog/PrettyPrint/Direct.fr

cspm-frontend: tools libraries
	@echo "[1;42mMaking $@[0m"
	$(BASH) Tools/src/Scripts/DeriveDataTypeable.sh "$(FREGE)"
	
	$(FREGEC) -d $(BUILD) -make -sp "CSPM-Frontend/__DataTypeable" \
		Token__LexError.fr
	
	$(JAVAC) -d $(BUILD) CSPM-Frontend/src/Language/CSPM/LexErrorException.java
	
	$(FREGEC) -d $(BUILD) -make -sp "CSPM-Frontend/__DataTypeable" \
		TokenClasses.fr \
		SrcLoc.fr \
		AlexWrapper.fr \
		Token.fr
	
	$(ALEX) CSPM-Frontend/src/Language/CSPM/Lexer.x
	$(BASH) Tools/src/Scripts/AlexToFrege.sh CSPM-Frontend/src/Language/CSPM/Lexer.hs "$(FREGE)"
	@echo "Compiling the lexer can take a while ..."
	$(FREGEC) -d $(BUILD) -make CSPM-Frontend/src/Language/CSPM/Lexer.fr
	
	$(FREGEC) -d $(BUILD) -make -sp "CSPM-Frontend/__DataTypeable" \
		AST.fr \
		UnicodeSymbols.fr \
		LexHelper.fr \
		CSPM-Frontend/src/Text/ParserCombinators/Parsec/ExprM.hs \
		BuiltIn.fr \
		PrettyPrinter.fr \
		Parser__ParseError.fr \
		Rename__RenameError.fr
	
	$(JAVAC) -d $(BUILD) CSPM-Frontend/src/Language/CSPM/ParseErrorException.java CSPM-Frontend/src/Language/CSPM/RenameErrorException.java
	
	$(FREGEC) -d $(BUILD) -make -sp "CSPM-Frontend/__DataTypeable" \
		Parser.fr
	
# FATAL: Can't find context for Typeable.Typeable when run with -O --TODO bugreport
	$(FREGEC0) -d $(BUILD) -make -sp "CSPM-Frontend/__DataTypeable" \
		Rename.fr
	
	$(FREGEC) -d $(BUILD) -make -sp "CSPM-Frontend/__DataTypeable" \
		Utils.fr \
		AstUtils.fr \
		Frontend.fr


libraries: parsec syb misclibs

parsec:
	@echo "[1;42mMaking $@[0m"
	$(MKDIR_P) $(BUILD_DIRS)
	$(FREGEC) -d $(BUILD) -make -sp "Libraries/src/Text/ParserCombinators/Parsec" \
		Pos.fr \
		Error.fr \
		Prim.fr \
		Char.fr \
		Combinator.fr \
		Expr.fr \
		Parsec.fr \
		Token.fr \
		Language.fr

syb:
	@echo "[1;42mMaking $@[0m"
	$(MKDIR_P) $(BUILD_DIRS)
	$(JAVAC) -d $(BUILD) Libraries/src/com/netflix/frege/runtime/Fingerprint.java
	$(FREGEC) -d $(BUILD) -make -sp "Libraries/src/Data" \
		Fingerprint.fr \
		Typeable.fr \
		Data.fr \
		Generics/Aliases.fr \
		Generics/Schemes.fr \
		Generics/Builders.fr

misclibs:
	@echo "[1;42mMaking $@[0m"
	$(MKDIR_P) $(BUILD_DIRS)
	$(FREGEC) -d $(BUILD) -make -sp "Libraries/src" \
		Control/Monad/State.fr \
		Data/Map.fr \
		Data/IntMap.fr \
		Data/Set.fr \
		Data/Version.fr \
		System/FilePath.fr \
		Text/PrettyPrint.fr


tools: arraysplitter dataderiver

arraysplitter:
	@echo "[1;42mMaking $@[0m"
	$(MKDIR_P) $(BUILD_DIRS)
	$(FREGEC) -d $(BUILD_TOOLS) -make -sp "Tools/src" \
		ArraySplitter/Main.fr

dataderiver: syb parsec
	@echo "[1;42mMaking $@[0m"
	$(MKDIR_P) $(BUILD_DIRS)
	$(FREGEC) -d $(BUILD_TOOLS) -make -sp "Tools/src/DataDeriver" \
		AST.fr \
		Deriver.fr \
		Main.fr \
		Parser.fr \
		Preprocessor.fr

clean:
	@echo "[1;42mMaking $@[0m"
	$(RM) $(BUILD_DIRS)
