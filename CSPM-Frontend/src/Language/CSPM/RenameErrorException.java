package frege.language.CSPM;

import frege.language.CSPM.Rename;

public class RenameErrorException extends Exception {
    Rename.TRenameError RenameError;
    public RenameErrorException(Rename.TRenameError err) {
        super("RenameErrorException: " +  Rename.IShow_RenameError.show(err));
        RenameError = err;
    }
    public Rename.TRenameError getRenameError() {
        return RenameError;
    }
}
