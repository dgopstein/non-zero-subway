object CarParser {
  def parse(carFile: java.io.File): Map[String, String] = parse(io.Source.fromFile(carFile).mkString)
  def parse(carFile: String): Map[String, String] =
    """(?m)(^[A-Z]\w*):([^:]*$)""".r
      .findAllMatchIn(carFile)
      .map(_.subgroups)
      .map(x => x(0) -> x(1).trim)
      .toMap
}

