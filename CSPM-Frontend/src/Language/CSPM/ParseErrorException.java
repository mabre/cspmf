package frege.language.CSPM;

import frege.language.CSPM.Parser_ParseError;

/**
 * Wraps Language.CSPM.ParseError in a native Java Exception
 * such that it can be thrown in Frege code.
 */
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
