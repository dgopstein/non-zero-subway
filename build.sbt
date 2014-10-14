scalaSource in Test := baseDirectory.value / "test"

libraryDependencies += "org.scalatest" % "scalatest_2.10" % "2.2.1"

// Show full stack trace
testOptions in Test += Tests.Argument(TestFrameworks.ScalaTest, "-oF")