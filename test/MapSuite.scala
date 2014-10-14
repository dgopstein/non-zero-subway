import org.scalatest._
import util.MapImplicits._

class MapSuite extends FunSuite {
  test("Map#invert") {
    assert(Map(1 -> "one", 2 -> "two").invert === Map("one" -> 1, "two" -> 2))
  }
}