import org.scalatest._
import subway.CarParser._
import subway.Subway._

class CarParserSuite extends FunSuite {
  test("CarParser.parse") {
    val parsedPlan = parsePlan(
      "----v--\n"+
      "XRD    \n"+
      "     LU\n"+
      "---^---\n")

    val targetPlan = Seq[Seq[Spot]](
      Seq(Wall, Wall, Wall, Wall, Door(Rightward), Wall, Wall),
      Seq(Obstacle, Seat(Forward), Seat(Rightward), Floor, Floor, Floor, Floor),
      Seq(Floor, Floor, Floor, Floor, Floor, Seat(Backward), Seat(Leftward)),
      Seq(Wall, Wall, Wall, Door(Leftward), Wall, Wall, Wall)
    )

    val zipped = parsedPlan.zip(targetPlan)

    assert(zipped.forall{case (x, y) => x == y}, "These should be equal: \n"+zipped.mkString("\n"))
  }
}