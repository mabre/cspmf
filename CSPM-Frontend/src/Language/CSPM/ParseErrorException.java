package frege.language.CSPM;

import frege.language.CSPM.Parser;

public class ParseErrorException extends Exception {
    Parser.TParseError parseError;
    public ParseErrorException(Parser.TParseError err) {
        super("ParseErrorException: " +  Parser.IShow_ParseError.show(err));
        parseError = err;
    }
    public Parser.TParseError getParseError() {
        return parseError;
    }
}
