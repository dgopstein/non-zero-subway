package util

object MapUtil {
  def invert[A, B](m: Map[A, B]) = m map(_.swap)
}

trait MapImplicits {
  implicit class RichMap[A, B](self: Map[A, B]) {
    def invert = MapUtil.invert(self)
  }
}

object MapImplicits extends util.MapImplicits