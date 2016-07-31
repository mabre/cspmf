package frege.language.CSPM;

import frege.language.CSPM.Rename__RenameError;

/**
 * Wraps Language.CSPM.RenameError in a native Java Exception
 * such that it can be thrown in Frege code.
 */
public class RenameErrorException extends Exception {
    Rename__RenameError.TRenameError RenameError;
    public RenameErrorException(Rename__RenameError.TRenameError err) {
        super("RenameErrorException: " +  Rename__RenameError.IShow_RenameError.show(err));
        RenameError = err;
    }
    public Rename__RenameError.TRenameError getRenameError() {
        return RenameError;
    }
}
