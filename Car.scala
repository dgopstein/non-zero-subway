package subway

object Subway {
  trait Orientation

  case object Forward extends Orientation
  case object Backward extends Orientation
  case object Leftward extends Orientation
  case object RightWard extends Orientation


  trait Spot

  case object Stanchion extends Spot
  case class Seat(direction: Orientation) extends Spot
  case object Railing extends Spot

  case class Car(footprint: Array[Array[Spot]])

  class R160 extends Car(Array(Array()))

  Array(1,2)
}

