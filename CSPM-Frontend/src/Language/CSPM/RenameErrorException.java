package frege.language.CSPM;

import frege.language.CSPM.Rename__RenameError;

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
