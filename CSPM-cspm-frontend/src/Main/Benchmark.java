package frege.main;

import frege.main.Main;
import frege.main.FregeInterface;
import frege.main.ExecCommand;
import frege.language.CSPM.AST.TModule;
import frege.language.CSPM.TranslateToProlog;
import static frege.main.FregeInterface.evaluateIOFunction;
import frege.runtime.WrappedCheckedException;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.function.Consumer;
import java.util.LinkedList;
import java.util.stream.*;

public class Benchmark {

    /**
     * Measures the runtime of a call with --prologOut or --translateDecl.
     * @param args[0] prologOut or translateDecl
     * @param args[1] number of repetitions
     * @param args[2] the file to be translated
     * @param args[3] (optional) declaration for --translateDecl
     */
    public static void main(String[] args) {
        if(args.length < 3) {
            System.out.println("too few arguments");
            return;
        }
        
        int repetitions = Integer.parseInt(args[1]);
        String filename = args[2];
        String[] cmdArgs = new String[3];
        
        switch(args[0].charAt(0)) {
            case 'p':
                cmdArgs[0] = "translate";
                cmdArgs[1] = "--prologOut=" + filename + ".pl";
                cmdArgs[2] = filename;
                benchmark(repetitions, Main::main, cmdArgs);
                break;
            case 't':
                cmdArgs[0] = filename;
                cmdArgs[1] = args.length > 2 ? args[3] : "N";
                benchmark(repetitions, Benchmark::translateDeclRun, cmdArgs);
                break;
            default:
                System.out.println("unknown option " + args[0]);
        }
    }
    
    /**
     * Calls translateDeclToPrologTerm' after generating an ast.
     * @param args[0] CSPM file
     * @param args[1] declaration
     */
    private static void translateDeclRun(String[] args) {
        System.out.println("Reading file ...");
        String spec = "";
        try {
            spec = new String(Files.readAllBytes(Paths.get(args[0])));
        } catch(IOException e) {
            System.out.println(e.getMessage());
        }
        
        try {
            System.out.println("Tokenzing and parsing ...");
            long start = System.currentTimeMillis();
            TModule ast = (TModule)evaluateIOFunction(
                TranslateToProlog.translateToAst(spec)
            );
            long end = System.currentTimeMillis();
            
            System.out.println("Done. (" + (end-start) + " ms)");
            System.out.println(TranslateToProlog.showModuleTokens(ast));
            
            System.out.println("Translating Declaration ...");
            start = System.currentTimeMillis();
            String term = (String)evaluateIOFunction(
                TranslateToProlog.translateDeclToPrologTerm$tick(
                    ast,
                    args[1]
                )
            );
            end = System.currentTimeMillis();
            
            System.out.println("Done. (" + (end-start) + " ms)");
            System.out.println(term);
        } catch(WrappedCheckedException e) {
            System.out.println(e.getCause().getMessage());
        }
    }
    
    private static void benchmark(int repetitions, Consumer<String[]> f, String[] args) {
        LinkedList<Long> runtimes = new LinkedList<>();
        
        long loopStart = System.currentTimeMillis();
        for(int i = 0; i < repetitions; i++) {
            
            long start = System.currentTimeMillis();
            f.accept(args);
            long end  = System.currentTimeMillis();
            
            Long runtime = end - start;
            System.out.println("run " + i + ": " + runtime);
            runtimes.add(runtime);
        }
        long loopEnd = System.currentTimeMillis();
        runtimes.forEach(s -> System.out.print(s + ", "));
        System.out.println();
        
        long runtimesSum = runtimes.stream().mapToLong(Long::longValue).sum();
        double runtimesAvg = (double)runtimesSum / repetitions;
        double runtimesAvgHalf = runtimes.subList(runtimes.size()/2, runtimes.size()).stream().mapToLong(Long::longValue).average().getAsDouble();
        
        System.out.println("total time: " + runtimesSum);
        System.out.println("average time: " + runtimesAvg);
        System.out.println("average time for second half: " + runtimesAvgHalf);
        System.out.println("benchmark wallclock time: " + (loopEnd - loopStart));
    }
    
}
