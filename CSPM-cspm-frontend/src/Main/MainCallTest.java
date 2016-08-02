import frege.run8.Func;
import frege.run8.Lazy;
import frege.run8.Thunk;
import frege.run.Kind;
import frege.run.RunTM;
import frege.runtime.Meta;
import frege.runtime.Phantom.RealWorld;
import frege.Prelude;
import frege.main.ExecCommand;
import frege.prelude.PreludeBase;

public class MainCallTest {

    public static void main(String[] args) {
    
        for(int i=0; i<20; i++) {
            long start = System.currentTimeMillis();
        
            PreludeBase.TST.<Short>performUnsafe(
                ExecCommand.prologOut("CSPM-Frontend/test/cspm/abp.csp",
                                      (Lazy<String>) (() -> "/tmp/abp324.pl")
            )).call();
            
            long end = System.currentTimeMillis();
            
            System.out.println("Done. (" + (end-start) + " ms)");
        }
    
    }

}