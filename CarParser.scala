package subway

import util.MapUtil
import Subway._

object CarParser {
  def parse(carFile: java.io.File): Car = parse(io.Source.fromFile(carFile).mkString)
  def parse(carFile: String): Car = Car(parsePlan(parseSections(carFile)("Class")))

  val charToSpot = Map[Char, Spot](
    'R' -> Seat(Forward),
    'L' -> Seat(Backward),
    'D' -> Seat(Rightward),
    'U' -> Seat(Leftward),
    'X' -> Obstacle,
    '-' -> Wall,
    'v' -> Door(Rightward),
    '^' -> Door(Leftward),
    ' ' -> Floor
  ).withDefault(x => throw new Exception(s"Unknown Car definition character '$x'"))

  val spotToChar = MapUtil.invert(charToSpot)

  def parsePlan(plan: String) =
    plan.split("\n")
        .map(_.map(charToSpot))

  def writePlan(car: Car): String = writePlan(car.footprint)
  def writePlan(footprint: Seq[Seq[Spot]]): String = footprint.map(_.map(spotToChar.apply).mkString).mkString("\n")

  def parseSections(carFile: String) =
    """(?m)(^[A-Z]\w*):([^:]*$)""".r
      .findAllMatchIn(carFile)
      .map(_.subgroups)
      .map(x => x(0) -> x(1).trim)
      .toMap
}

