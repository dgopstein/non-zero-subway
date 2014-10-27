require 'csv'
require 'ruby-processing'
Processing::App::SKETCH_PATH = __FILE__

def draw
  #class MySketch < Processing::App
  Class.new(Processing::App) do
    def setup
      size 200, 200
      background 0
      smooth
    end
  
    def draw
      fill 255, 102, 18
      ellipse 56, 46, 55, 55
    end
  end
end

class CarCsvImporter
  def initialize(filename)
    @filename = filename
    @csv = CSV.open(filename)
  end

  def csv; @csv; end

  def car(car_type)
    
  end
end

#MySketch.new(x: 10, y: 30)
