package frege.language.CSPM;

import frege.language.CSPM.Token__LexError;

public class LexErrorException extends Exception {
    Token__LexError.TLexError lexError;
    public LexErrorException(Token__LexError.TLexError err) {
        super("LexErrorException: " +  Token__LexError.IShow_LexError.show(err));
        lexError = err;
    }
    public Token__LexError.TLexError getLexError() {
        return lexError;
    }
}
