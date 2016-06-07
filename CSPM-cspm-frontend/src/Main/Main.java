package frege.main;

import frege.main.ExecCommand;
import org.apache.commons.cli.*;
import org.apache.commons.cli.Option.*;

public class Main {

    /**
     * main-funtion for the command line.
     */
    public static void main(String[] args) {
        Options options = new Options();
        options.addOption("?", "help", false, "Display help message");
        options.addOption("V", "version", false, "Print version information");
        options.addOption(Option.builder()
                                .longOpt("numeric-version")
                                .desc("Print just the version number")
                                .build());
        options.addOption("v", "verbose", false, "verbose");
        options.addOption(Option.builder()
                                .longOpt("rename")
                                .desc("run renaming on the AST")
                                .build());
        options.addOption(Option.builder()
                                .longOpt("prettyOut")
                                .desc("prettyPrint to a file")
                                .hasArg()
                                .argName("FILE")
                                .build());
        options.addOption(Option.builder()
                                .longOpt("addUnicode")
                                .desc("replace some CSPM symbols with unicode")
                                .hasArg()
                                .argName("FILE")
                                .build());
        options.addOption(Option.builder()
                                .longOpt("removeUnicode")
                                .desc("replace some unicode symbols with default CSPM encoding")
                                .hasArg()
                                .argName("FILE")
                                .build());
        options.addOption(Option.builder()
                                .longOpt("prologOut")
                                .desc("translate a CSP-M file to Prolog")
                                .hasArg()
                                .argName("FILE")
                                .build());
        options.addOption(Option.builder()
                                .longOpt("expressionToPrologTerm")
                                .desc("translate a single CSP-M expression to Prolog")
                                .hasArg()
                                .argName("STRING")
                                .build());
        options.addOption(Option.builder()
                                .longOpt("declarationToPrologTerm")
                                .desc("translate a single CSP-M declaration to Prolog")
                                .hasArg()
                                .argName("STRING")
                                .build());
        
        CommandLineParser parser = new DefaultParser();
        try {
            CommandLine cmdLine = parser.parse(options, args);
            
            String[] arguments = cmdLine.getArgs();
            
            if(cmdLine.hasOption("help")) {
                // TODO seperate translate/info
                HelpFormatter formatter = new HelpFormatter();
                formatter.printHelp("cspmf translate", options);
            } else if(cmdLine.hasOption("version")) {
                evaluateFregeIOFunction(ExecCommand.version);
            } else if(cmdLine.hasOption("numeric-version")) {
                evaluateFregeIOFunction(ExecCommand.numericVersion);
            } else if(cmdLine.hasOption("verbose")
                      || arguments.length > 0 && arguments[0].equals("info")) {
                evaluateFregeIOFunction(ExecCommand.verbose);
            } else if(arguments.length == 2) {
                if(arguments[0].equals("translate")) {
                    String src = arguments[1];
                    boolean rename = cmdLine.hasOption("rename");
                    if(cmdLine.hasOption("prettyOut")) {
                        String outFile = cmdLine.getOptionValue("prettyOut");
                        evaluateFregeIOFunction(ExecCommand.prettyOut(src, rename, outFile));
                    }
                    if(cmdLine.hasOption("addUnicode")) {
                        String outFile = cmdLine.getOptionValue("addUnicode");
                        evaluateFregeIOFunction(ExecCommand.addUnicode(src, outFile));
                    }
                    if(cmdLine.hasOption("removeUnicode")) {
                        String outFile = cmdLine.getOptionValue("removeUnicode");
                        evaluateFregeIOFunction(ExecCommand.removeUnicode(src, outFile));
                    }
                    if(cmdLine.hasOption("prologOut")) {
                        String outFile = cmdLine.getOptionValue("prologOut");
                        evaluateFregeIOFunction(ExecCommand.prologOut(src, outFile));
                    }
                    if(cmdLine.hasOption("expressionToPrologTerm")) {
                        String expr = cmdLine.getOptionValue("expressionToPrologTerm");
                        evaluateFregeIOFunction(ExecCommand.expressionToPrologTerm(src, expr));
                    }
                    if(cmdLine.hasOption("declarationToPrologTerm")) {
                        String decl = cmdLine.getOptionValue("declarationToPrologTerm");
                        evaluateFregeIOFunction(ExecCommand.declarationToPrologTerm(src, decl));
                    }
                    if(cmdLine.getOptions().length == 0) {
                        System.out.println("No output option is set");
                        System.out.println("Set '--xmlOut', '--prettyOut' or an other output option");
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
     * Evaluates the given return object of a (lazy) frege function with frege return type IO ()
     * @param res The result of calling the frege function with all parameters applied
     */
    private static void evaluateFregeIOFunction(Object res) {
        frege.runtime.Runtime.runMain(
            frege.prelude.PreludeBase.TST.performUnsafe(
                frege.runtime.Delayed.<frege.runtime.Lambda>forced(
                    res
                )
            )
        );
    }
}
