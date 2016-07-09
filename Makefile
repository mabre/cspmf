BUILD       = build
BUILD_TOOLS = Tools/build
BUILD_DIRS  = $(BUILD) $(BUILD_TOOLS)
DIST        = dist

FREGEJAR = /home/markus/Downloads/frege/fregec.jar
ALEX     = /home/markus/.cabal/bin/alex
CLIJAR   = Libraries/commons-cli-1.3.1.jar
JAVAC    = javac -cp $(FREGEJAR):${BUILD}:$(CLIJAR)
JAVA     = java
MKDIR_P  = mkdir -p
RM       = rm -rf
BASH     = bash
CP       = cp
CP_P     = cp --parents
CLASS_FILES = `find $(BUILD) -name "*class"`

FREGEC_ARGS = -hints -O
FREGEC0     = $(JAVA) -Xss16m -Xmx2g -jar $(FREGEJAR) -fp ${BUILD}:${BUILD_TOOLS}
FREGEC      = $(FREGEC0) $(FREGEC_ARGS)
FREGE       = $(JAVA) -Xss16m -Xmx2g -cp $(FREGEJAR):${BUILD}:${BUILD_TOOLS}


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

cspm-frontend: dataderiver libraries
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
	$(BASH) Tools/src/Scripts/AlexToFrege.sh CSPM-Frontend/src/Language/CSPM/Lexer.hs
	
	$(FREGEC) -d $(BUILD) -make -sp "CSPM-Frontend/__DataTypeable" \
		CSPM-Frontend/src/Language/CSPM/Lexer.fr \
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


dist: cspmf
	@echo "[1;42mMake $@[0m"
	$(MKDIR_P) $(DIST)
	$(CP_P) $(CLASS_FILES) $(DIST)
	$(CP) $(FREGEJAR) $(DIST)/frege.jar
	$(CP) $(CLIJAR) $(DIST)/commons-cli.jar


clean:
	@echo "[1;42mMaking $@[0m"
	$(RM) $(BUILD_DIRS)
