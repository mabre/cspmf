BUILD  = build
DIST   = dist
DOC    = doc

FREGEJAR = frege.jar
ALEX     = alex
PROGUARD = proguard
CLIJAR   = Libraries/commons-cli-1.3.1.jar
JAVAC    = javac -cp $(FREGEJAR):${BUILD}:$(CLIJAR)
JAVA     = java
JAR      = jar
DIFF     = diff -Z
MKDIR_P  = mkdir -p
RM       = rm -rf
MV       = mv
BASH     = bash
CP       = cp
CP_P     = cp --parents
OR_TRUE  = || true
TOUCH    = touch

FREGECFLAGS = -make -hints -O
FREGEC0     = $(JAVA) -Xss16m -Xmx2g -jar $(FREGEJAR) -fp ${BUILD} -d $(BUILD)
FREGEC      = $(FREGEC0) $(FREGECFLAGS)
FREGE       = $(JAVA) -Xss16m -Xmx2g -cp $(FREGEJAR):${BUILD}
 
TESTSDIR  = CSPM-Frontend/test
TESTFILES = $(notdir $(wildcard $(TESTSDIR)/cspm/*))
TMP       = /tmp


cspmf: cspm-cspm-frontend
	@echo "[1;42mMade $@[0m"

cspm-cspm-frontend: cspm-toprolog
	@echo "[1;42mMaking $@[0m"
	
	$(FREGEC) -sp CSPM-cspm-frontend/src \
		Language/CSPM/AstToXML.fr \
		Main/ExecCommand.fr \
		Main/ExceptionHandler.fr
	
	$(JAVAC) -d $(BUILD) CSPM-cspm-frontend/src/Main/Main.java CSPM-cspm-frontend/src/Main/FregeInterface.java CSPM-cspm-frontend/src/Main/Benchmark.java

cspm-toprolog: cspm-frontend
	@echo "[1;42mMaking $@[0m"
	
	$(FREGEC) -sp "CSPM-ToProlog/src/Language" \
		CSPM/CompileAstToProlog.fr \
		CSPM/TranslateToProlog.fr \
		Prolog/PrettyPrint/Direct.fr

cspm-frontend: dataderiver libraries
	@echo "[1;42mMaking $@[0m"
	$(BASH) Tools/src/Scripts/DeriveDataTypeable.sh "$(FREGE)"
	
	$(FREGEC) -sp "CSPM-Frontend/__DataTypeable" \
		TokenClasses.fr \
		SrcLoc.fr \
		AlexWrapper.fr \
		CspmException.fr \
		Token.fr \
		Token__LexError.fr \
		Token__LexErrorException.fr
	
	$(ALEX) CSPM-Frontend/src/Language/CSPM/Lexer.x
	$(BASH) Tools/src/Scripts/AlexToFrege.sh CSPM-Frontend/src/Language/CSPM/Lexer.hs
	
	$(FREGEC) -sp "CSPM-Frontend/__DataTypeable" \
		CSPM-Frontend/src/Language/CSPM/Lexer.fr \
		AST.fr \
		UnicodeSymbols.fr \
		LexHelper.fr \
		CSPM-Frontend/src/Text/ParserCombinators/Parsec/ExprM.hs \
		BuiltIn.fr \
		PrettyPrinter.fr \
		Parser__ParseError.fr \
		Parser__ParseErrorException.fr \
		Rename__RenameError.fr \
		Rename__RenameErrorException.fr \
		Parser.fr
	
# FATAL: Can't find context for Typeable.Typeable when run with -O
# https://github.com/Frege/frege/issues/297
	$(FREGEC0) -make -sp "CSPM-Frontend/__DataTypeable" \
		Rename.fr
	
	$(FREGEC) -sp "CSPM-Frontend/__DataTypeable" \
		Utils.fr \
		AstUtils.fr \
		Frontend.fr


libraries: parsec syb xml backports misclibs

parsec:
	@echo "[1;42mMaking $@[0m"
	$(MKDIR_P) $(BUILD)
	$(FREGEC) -sp "Libraries/src/Text/ParserCombinators/Parsec" \
		Pos.fr \
		Error.fr \
		Prim.fr \
		Char.fr \
		Combinator.fr \
		Expr.fr \
		Parsec.fr \
		Token.fr \
		Language.fr

syb: backports
	@echo "[1;42mMaking $@[0m"
	$(MKDIR_P) $(BUILD)
	$(JAVAC) -d $(BUILD) Libraries/src/com/netflix/frege/runtime/Fingerprint.java
	$(FREGEC) -sp "Libraries/src/Data" \
		Fingerprint.fr \
		Typeable.fr \
		Data.fr \
		Generics/Aliases.fr \
		Generics/Schemes.fr \
		Generics/Builders.fr


xml: syb
	@echo "[1;42mMaking $@[0m"
	$(MKDIR_P) $(BUILD)
	$(FREGEC) -sp "Libraries/src/Text/XML/Light" \
		Light.fr \
		Output.fr \
		Types.fr

backports:
	@echo "[1;42mMaking $@[0m"
	$(MKDIR_P) $(BUILD)
	$(FREGEC) -sp "Libraries/src" \
		Data/Array.fr \
		System/Environment.fr \
		System/Exit.fr

misclibs: syb
	@echo "[1;42mMaking $@[0m"
	$(MKDIR_P) $(BUILD)
	$(FREGEC) -sp "Libraries/src" \
		Control/Monad/State.fr \
		Data/DList.fr \
		Data/Map.fr \
		Data/IntMap.fr \
		Data/Set.fr \
		Data/Version.fr \
		System/FilePath.fr \
		Text/PrettyPrint.fr


tools: arraysplitter dataderiver

arraysplitter:
	@echo "[1;42mMaking $@[0m"
	$(MKDIR_P) $(BUILD)
	$(FREGEC) -sp "Tools/src" \
		ArraySplitter/Main.fr

dataderiver: syb parsec
	@echo "[1;42mMaking $@[0m"
	$(MKDIR_P) $(BUILD)
	$(FREGEC) -sp "Tools/src/DataDeriver" \
		AST.fr \
		Deriver.fr \
		Main.fr \
		Parser.fr \
		Preprocessor.fr


jar:
	@echo "[1;42mMake $@[0m"
	@echo Note that you might have to change the paths in pg.conf.
	@echo In case of error messages about unresolved references to program class members try running make clean \&\& make cspmf.
	proguard @pg.conf
	$(JAR) -ufve cspmf.jar frege.main.Main


.PHONY: doc
doc:
	@echo "[1;42mMake $@[0m"
	$(MKDIR_P) $(DOC) # exclude non-Frege classes (the compiler should ignore them automatically, but for some reason it doesn't)
	$(FREGE) frege.tools.Doc -x \
		frege.language.CSPM.LexErrorException,frege.language.CSPM.ParseErrorException,frege.language.CSPM.RenameErrorException,frege.main.Benchmark,frege.main.FregeInterface,frege.main.Main,com.netflix.frege.runtime.Fingerprint \
		-d $(DOC) $(BUILD)


.PHONY: test %.csp %.fdr test-toProlog
test: test-syb test-cspmf
	@echo "[1;42mTesting done[0m"

test-syb:
	@echo "[1;42mTesting SYB[0m"
	$(FREGEC) -sp "Libraries/test/Syb" \
		DataTest.fr \
		EverywhereTest.fr \
		ListTest.fr \
		StringTest.fr \
		TupleTest.fr \
		TypeTest.fr
	$(FREGE) frege.syb.DataTest
	$(FREGE) frege.syb.EverywhereTest
	$(FREGE) frege.syb.ListTest
	$(FREGE) frege.syb.StringTest
	$(FREGE) frege.syb.TupleTest
	$(FREGE) frege.syb.TypeTest

test-filepath:
	@echo "[1;42mTesting System.FilePath[0m"
	$(FREGEC) -sp "Libraries/test" \
		FilePathTest.fr
	$(FREGE) frege.filePath.Test


test-cspmf: $(TESTFILES) test-toProlog

test-toProlog:
	@echo "[1;42mTesting toProlog[0m"
	./cspmf.sh translate --expressionToPrologTerm="N" $(TESTSDIR)/cspm/very_simple.csp > $(TMP)/simple.csp.expression
	@$(DIFF) "$(TESTSDIR)/toProlog/simple.csp.expression" $(TMP)/simple.csp.expression || \
	(echo "Test $@ failed" && exit 1)
	./cspmf.sh translate --declarationToPrologTerm="datatype D = F" $(TESTSDIR)/cspm/very_simple.csp > $(TMP)/simple.csp.declaration
	@$(DIFF) "$(TESTSDIR)/toProlog/simple.csp.declaration" $(TMP)/simple.csp.declaration || \
	(echo "Test $@ failed" && exit 1)

# Test that
# * the outputs of --prologOut and --xmlOut match the reference output
# * prettyOut(file) == removeUnicode(addUnicode(prettyOut(file)))
%.csp:
	@echo "[1;42mTesting $@[0m"
	$(RM) $(TMP)/$@.pl
	./cspmf.sh translate --prologOut=$(TMP)/$@.pl $(TESTSDIR)/cspm/$@
	@$(DIFF) "$(TESTSDIR)/prolog/$@.pl" $(TMP)/$@.pl || \
	(echo "Test $@ failed" && exit 1)
	$(RM) $(TMP)/$@.xml
	$(TOUCH) $(TMP)/$@.xml
	./cspmf.sh translate --xmlOut=$(TMP)/$@.xml $(TESTSDIR)/cspm/$@ $(OR_TRUE)
	@$(DIFF) "$(TESTSDIR)/xml/$@.xml" $(TMP)/$@.xml || \
	(echo "Test $@ failed" && exit 1)
	$(RM) $(TMP)/$@.pretty.csp $(TMP)/$@.unicode.csp $(TMP)/$@.nounicode.csp
	$(TOUCH) $(TMP)/$@.pretty.csp $(TMP)/$@.unicode.csp $(TMP)/$@.nounicode.csp
	./cspmf.sh translate --prettyOut=$(TMP)/$@.pretty.csp $(TESTSDIR)/cspm/$@ $(OR_TRUE)
	./cspmf.sh translate --addUnicode=$(TMP)/$@.unicode.csp $(TMP)/$@.pretty.csp
	./cspmf.sh translate --removeUnicode=$(TMP)/$@.nounicode.csp $(TMP)/$@.unicode.csp
	@$(DIFF) "$(TMP)/$@.pretty.csp" $(TMP)/$@.nounicode.csp || \
	(echo "Test $@ failed" && exit 1)

%.fdr2:
	@echo "[1;42mTesting $@[0m"
	$(RM) $(TMP)/$@.pl
	./cspmf.sh translate --prologOut=$(TMP)/$@.pl $(TESTSDIR)/cspm/$@
	@$(DIFF) "$(TESTSDIR)/prolog/$@.pl" $(TMP)/$@.pl || \
	(echo "Test $@ failed" && exit 1)
	$(RM) $(TMP)/$@.xml
	$(TOUCH) $(TMP)/$@.xml
	./cspmf.sh translate --xmlOut=$(TMP)/$@.xml $(TESTSDIR)/cspm/$@ $(OR_TRUE)
	@$(DIFF) "$(TESTSDIR)/xml/$@.xml" $(TMP)/$@.xml || \
	(echo "Test $@ failed" && exit 1)
	$(RM) $(TMP)/$@.pretty.csp $(TMP)/$@.unicode.csp $(TMP)/$@.nounicode.csp
	$(TOUCH) $(TMP)/$@.pretty.csp $(TMP)/$@.unicode.csp $(TMP)/$@.nounicode.csp
	./cspmf.sh translate --prettyOut=$(TMP)/$@.pretty.csp $(TESTSDIR)/cspm/$@ $(OR_TRUE)
	./cspmf.sh translate --addUnicode=$(TMP)/$@.unicode.csp $(TMP)/$@.pretty.csp
	./cspmf.sh translate --removeUnicode=$(TMP)/$@.nounicode.csp $(TMP)/$@.unicode.csp
	@$(DIFF) "$(TMP)/$@.pretty.csp" $(TMP)/$@.nounicode.csp || \
	(echo "Test $@ failed" && exit 1)


.PHONY: clean
clean:
	@echo "[1;42mMaking $@[0m"
	$(RM) $(BUILD) $(DIST) $(DOC) CSPM-Frontend/__DataTypeable CSPM-Frontend/src/Language/CSPM/Lexer.hs CSPM-Frontend/src/Language/CSPM/Lexer.fr
