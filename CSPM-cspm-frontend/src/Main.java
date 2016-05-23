import frege.language.CSPM.TranslateToProlog;
import java.util.function.Supplier;

public class Main {

    public static void main(String[] args) {
        callFregeIOFunction(() -> TranslateToProlog.translateToProlog("/tmp/1", "/tmp/2"));
    }

    /**
     * Runs the given function with frege which returns the frege type IO ()
     * @param f A function calling the frege function with all parameters applied
     */
    private static void callFregeIOFunction(Supplier<Object> f) {
        frege.runtime.Runtime.runMain(
            frege.prelude.PreludeBase.TST.performUnsafe(
                frege.runtime.Delayed.<frege.runtime.Lambda>forced(
                    f.get()
                )
            )
        );
    }
}
