name := "TypeChef-LinuxAnalysis"

version := "0.3"

organization := "de.fosd.typechef"

scalaVersion := "2.9.1"

libraryDependencies += "de.fosd.typechef" %% "frontend" % "0.3.1"

libraryDependencies += "gnu.getopt" % "java-getopt" % "1.0.13"

libraryDependencies +="junit" % "junit" % "4.8.2" % "test"

libraryDependencies += "com.novocode" % "junit-interface" % "0.6" % "test"


//generate typechef.sh file with full classpath
TaskKey[File]("mkrun") <<= (baseDirectory, fullClasspath in Runtime, mainClass in Runtime) map { (base, cp, main) =>
  val template = """#!/bin/sh
java -ea -Xmx2G -Xms128m -Xss10m -classpath "%s" %s "$@"
"""
  val contents = template.format(cp.files.absString, "de.fosd.typechef.Frontend")
  val out = base / "typechefLinux.sh"
  IO.write(out, contents)
  out.setExecutable(true)
  out
}
