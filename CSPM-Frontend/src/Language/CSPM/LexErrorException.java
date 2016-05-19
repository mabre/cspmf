package frege.language.CSPM;

import frege.language.CSPM.Token;

public class LexErrorException extends Exception {
    Token.TLexError lexError;
    public LexErrorException(Token.TLexError err) {
        super("LexErrorException: " +  Token.IShow_LexError.show(err));
        lexError = err;
    }
    public Token.TLexError getLexError() {
        return lexError;
    }
}
