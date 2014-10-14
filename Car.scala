package subway

object Subway {
  trait Orientation

  case object Forward extends Orientation
  case object Backward extends Orientation
  case object Leftward extends Orientation
  case object Rightward extends Orientation


  sealed trait Spot
  //case object Railing extends Spot
  //case object Stanchion extends Spot
  case class Seat(direction: Orientation) extends Spot
  case object Floor extends Spot
  case object Obstacle extends Spot
  case object Wall extends Spot
  case class Door(direction: Orientation) extends Spot

  case class Car(footprint: Seq[Seq[Spot]])
}

