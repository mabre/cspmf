import frege.language.CSPM.TranslateToProlog;
import java.util.function.Supplier;
import org.apache.commons.cli.*;
import org.apache.commons.cli.Option.*;

public class Main {

    public static void main(String[] args) {
        Options options = new Options();
        options.addOption("?", "help", false, "Display help message");
        options.addOption("V", "version", false, "Print version information");
        options.addOption(Option.builder()
                                .longOpt("numeric-version")
                                .desc("Print just the version number")
                                .build());
        options.addOption(Option.builder()
                                .longOpt("prologOut")
                                .desc("translate a CSP-M file to Prolog")
                                .hasArg()
                                .argName("FILE")
                                .build());
        
        CommandLineParser parser = new DefaultParser();
        try {
            CommandLine cmdLine = parser.parse(options, args);
            
            String[] arguments = cmdLine.getArgs();
            
            if(cmdLine.hasOption("help")) {
                HelpFormatter formatter = new HelpFormatter();
                formatter.printHelp("cspmf translate", options);
            } else if(arguments.length == 2) {
                if(arguments[0].equals("translate")) {
                    if(cmdLine.hasOption("prologOut")) {
                        String outFile = cmdLine.getOptionValue("prologOut");
                        String src = arguments[1];
                        callFregeIOFunction(() -> TranslateToProlog.translateToProlog(src, outFile));
                    }
                } else {
                    System.err.println("Missing mode, wanted any of: info translate");
                }
            } else {
                System.err.println("Missing mode or output file.");
            }
        } catch(ParseException exp) {
            System.err.println(exp.getMessage());
        }
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
