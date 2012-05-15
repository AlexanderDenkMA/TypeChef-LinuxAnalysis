package de.fosd.typechef.linux

import java.io._
import xml.XML

/**
 * usage:
 *
 * errorList file outputFile
 * or
 * errorList -f filelist outputFile
 */
object ErrorList {

    def main(args: Array[String]) {
        assert(args.size > 0, "parameters expected: file outputfile")
        val (files, outStats) =
            if (args(0) == "-f")
                (scala.io.Source.fromFile(args(1)).getLines.toList, if (args.length > 2) args(2) else "errorList.csv")
            else
                (List(args(0)), if (args.length > 1) args(1) else "errorList.csv")
        val appendToOutput = args(0) != "-f"

        val out = new BufferedWriter(new FileWriter(outStats, appendToOutput))
        if (!appendToOutput)
            out.write("file;numAnyError;numSyntaxError;numReferenceError;criticalErrors;totalTypeError;comment\n")

        def append(s: String) {
            print(s)
            out.write(s)
        }
        def indent(s: String) = s + (" " * (40 - s.length))

        for (file <- files) {
            val fullFilePath = LinuxSettings.pathToLinuxSource + "/" + file + ".c.xml"

            if (!new File(fullFilePath).exists)
                append(indent(file) + ";;;;;;.c.xml file not found\n")
            else {
                append(indent(file) + ";")

                val errorXml = XML.load(new FileReader(fullFilePath))

                //total errors
                append((errorXml \ "_").size + ";")
                //parser errors
                append((errorXml \ "parsererror").size + ";")
                //reference errors
                append((errorXml \ "typeerror").filter(n =>
                    Set("Type-Lookup Error", "Id-Lookup Error", "Field-Lookup Error", "Error") contains (n \ "severity").text.trim).
                    size + ";")
                //critical errors
		append((errorXml \ "typeerror").filter(n =>
                    "Critical" == (n \ "severity").text.trim).
                    size + ";")
                //other errors
                append((errorXml \ "typeerror").size + ";")

                append("\n")
            }
        }

        out.close
    }
}

