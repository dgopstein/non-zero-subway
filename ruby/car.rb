require 'csv'
require 'ruby-processing'

require 'csv_importer.rb'

Processing::App::SKETCH_PATH = __FILE__


class Car
  attr_accessor :name, :plan

  def initialize(name)
    @name = name
    @plan = []
  end

  def height
    plan.first.size
  end

  def width
    plan.size
  end
end

Space = Struct.new(:car_class, :space, :position, :pole, :wall, :door, :map, :legroom, :perpendicular, :seat_pole, :vestibule)

class CarImporter
  include CsvImporter

  attr_accessor :cars

  def initialize(filename)
    super(filename)
    @cars = parse_csv(@csv)
  end

  def self.parse_space(str)
    space_col, space_row = str.match(/([0-9.]+)(\w+)/).captures
    [2*(space_col.to_f - 1), 2*(space_row.downcase.ord - 'a'.ord)]
  end

  def parse_csv(csv)
    csv.drop(1).each_with_object({}) do |row, cars|
      space = Space.new(*row.to_a)

      #TODO this isn't parsing and should probs live somewhere else
      car = (cars[space.car_class] ||= Car.new(space.car_class))

      # split a spot description e.g., '10d' into its vertical and horizontal components, [10, d]
      space_col, space_row = CarImporter.parse_space(space.space)

      car_col = (car.plan[space_col] ||= [])

      car_col[space_row] = Space.new(*row.to_a)
    end
  end
end


class CarVisualizer < Processing::App
#  Class.new(Processing::App) do
  def initialize(car)
    @car = car
    @seat_size = 20
    super(x: 20, y: 30) # what does this mean?
  end

  def setup
    size (@car.width+1)*@seat_size, (@car.height+1)*@seat_size
    background 255
    smooth
  end
  
  def draw
    @car.plan.each_with_index do |col, col_num|
      col and col.each_with_index do |record, row_num|
        x = col_num*@seat_size
        y = row_num*@seat_size
        if record
          if record.pole > 0
            fill 102, 255, 18
            rect(x, y, @seat_size/2, @seat_size/2)
          elsif record.position > 0
            fill 255, 102, 18
            rect(x, y, @seat_size*2, @seat_size*2)
          end
          fill 0, 0, 0
          f = createFont("Arial",16,true)
          textFont(f, 11)
          text(record.space, x, y+@seat_size)
        end
      end
    end
  end
end
#class CarVisualizer < Processing::App
#  def self.seat_size; 20; end
#  def self.draw(car)
#
#    c = Class.new(Processing::App) do
#      def setup
#        size car.width*CarVisualizer.seat_size, car.height*CarVisualizer.seat_size
#        background 0
#        smooth
#      end
#    
#      def draw
#        car.each do |col|
#          col.each do |row|
#            fill 255, 102, 18
#            x = col*CarVisualizer.seat_size
#            y = row*CarVisualizer.seat_size
#            rectangle x, y, CarVisualizer.seat_size, CarVisualizer.seat_size
#          end
#        end
#      end
#    end
#
#    c.new(x: 0, y: 0)
#  end
#end

#MySketch.new(x: 10, y: 30)
