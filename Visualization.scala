import java.awt.{Frame, BorderLayout}
import java.awt.event.{WindowAdapter, WindowEvent, WindowListener}
import processing.core._
import processing.core.PConstants._
import subway.Subway._


object Visualization {
  val squareSize = 20

  def carWidth(plan: Seq[Seq[_]]) = squareSize * plan.head.length
  def carHeight(plan: Seq[Seq[_]]) = squareSize * plan.length

  class CircleSketch(plan: Seq[Seq[Spot]]) extends PApplet {
    override def setup() {
      size(carWidth(plan), carHeight(plan))
      background(0)
    }
    override def draw() {
      background(0)
      fill(200)

      val seatColors = Seq[(Float, Float, Float)]((255, 0, 0), (255, 127, 0))

      def drawSeat(x: Int, y: Int, dir: Orientation) = {
        val (o1: Float, o2: Float, o3: Float, o4: Float) = dir match {
          case Forward   => (0f,            0f,  (-1f/3)*squareSize, 0f)
          case Backward  => ((1/3f)*squareSize, 0f,  (-1f/3)*squareSize, 0f)
          case Rightward => (0f,            0f,  0f, (-1f/3)*squareSize)
          case Leftward  => (0f, (1/3f)*squareSize,  0f, (-1f/3)*squareSize)
        }

        rect(squareSize * x + o1, squareSize * y + o2, squareSize + o3, squareSize + o4)
      }

      plan.zipWithIndex.foreach { case (lane, row) =>
        lane.zipWithIndex.foreach { case (spot, col) =>
          spot match {
            case Seat(dir) =>
              (fill(_:Float, _:Float, _:Float)).tupled(seatColors((col+row) % 2)) // (seatColors(col % 2))
              drawSeat(col, row, dir)
            case _ => // Nothing
          }
      }}

    }
  }

//  class DisplayFrame(plan: Seq[Seq[Spot]]) extends javax.swing.JFrame {
//    this.setSize(carWidth(plan)+50, carHeight(plan)+50); //The window Dimensions
//    setDefaultCloseOperation(javax.swing.WindowConstants.EXIT_ON_CLOSE);

//    val panel = new javax.swing.JPanel();
    //panel.setBounds(0, 0, 600, 600);
//    val sketch = new CircleSketch(plan);
//    panel.add(sketch)
//    this.add(panel, BorderLayout.WEST);
//    sketch.init(); //this is the function used to start the execution of the sketch
//    this.setVisible(true);
//  }

  //  def draw(plan: Seq[Seq[Spot]]) {
  //    new DisplayFrame(plan).setVisible(true);
  //  }

  class ExampleFrame(plan: Seq[Seq[Spot]]) extends Frame("Embedded Applet") {
    setLayout(new BorderLayout());

    this.setSize(carWidth(plan)+50, carHeight(plan)+50);
    val embed = new CircleSketch(plan)
    add(embed, BorderLayout.CENTER);

    // important to call this whenever embedding a PApplet.
    // It ensures that the animation thread is started and
    // that other internal variables are properly set.
    embed.init()

    this.addWindowListener(new WindowAdapter(){
      override def windowClosing(we: WindowEvent){
        embed.destroy()
        System.exit(0)
      }
    })
  }

  def draw(plan: Seq[Seq[Spot]]) {
    new ExampleFrame(plan).setVisible(true);
  }
}