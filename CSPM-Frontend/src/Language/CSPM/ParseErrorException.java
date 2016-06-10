package frege.language.CSPM;

import frege.language.CSPM.Parser_ParseError;

public class ParseErrorException extends Exception {
    Parser_ParseError.TParseError parseError;
    public ParseErrorException(Parser_ParseError.TParseError err) {
        super("ParseErrorException: " +  Parser_ParseError.IShow_ParseError.show(err));
        parseError = err;
    }
    public Parser_ParseError.TParseError getParseError() {
        return parseError;
    }
}
