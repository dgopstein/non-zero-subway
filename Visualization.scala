import processing.core._
import processing.core.PConstants._

object Vis {
  class CircleSketch extends PApplet {
    override def setup {
      size(400, 400);
      background(0);
    }
    override def draw {
      background(0);
      fill(200);
      ellipseMode(CENTER);
      ellipse(mouseX,mouseY,40,40);
    }
  }

  class DisplayFrame extends javax.swing.JFrame {
      this.setSize(600, 600); //The window Dimensions
      setDefaultCloseOperation(javax.swing.WindowConstants.EXIT_ON_CLOSE);
      val panel = new javax.swing.JPanel();
      panel.setBounds(20, 20, 600, 600);
      val sketch = new CircleSketch();
      panel.add(sketch);
      this.add(panel);
      sketch.init(); //this is the function used to start the execution of the sketch
      this.setVisible(true);
  }

  def main(args: Array[String]) {
    new DisplayFrame().setVisible(true);
  }
}