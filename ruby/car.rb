require 'csv'
require 'ruby-processing'

require 'csv_importer.rb'
require 'passenger.rb'

Processing::App::SKETCH_PATH = __FILE__


class Car
  attr_accessor :name, :plan

  def initialize(name)
    @name = name
    @plan = []
  end

  def height
    plan.map{|x| x.ergo.size || 0 }.max
  end

  def width
    plan.size
  end
end

Space = Struct.new(:car_class, :space, :position, :pole, :wall, :door, :map, :legroom, :perpendicular, :seat_pole, :vestibule)

def parse_space(str)
  space_col, space_row = str.match(/([0-9.]+)(\w+)/).captures
  [2*(space_col.to_f - 1), 2*(space_row.downcase.ord - 'a'.ord)]
end

class CarImporter
  include CsvImporter

  attr_accessor :cars

  def initialize(filename)
    super(filename)
    @cars = parse_csv(@csv)
  end

  def parse_csv(csv)
    csv.drop(1).each_with_object({}) do |row, cars|
      space = Space.new(*row.to_a)

      #TODO this isn't parsing and should probs live somewhere else
      car = (cars[space.car_class] ||= Car.new(space.car_class))

      # split a spot description e.g., '10d' into its vertical and horizontal components, [10, d]
      space_col, space_row = parse_space(space.space)

      car_col = (car.plan[space_col] ||= [])

      car_col[space_row] = Space.new(*row.to_a)
    end
  end
end

class CarVisualizer < Processing::App
  attr_accessor :passengers_by_stop, :stop

  def initialize(car, passengers_by_stop = [])
    @stop = 0
    @car = car
    @seat_size = 40
    @passengers_by_stop = passengers_by_stop
    super(x: 20, y: 30) # what does this mean?
  end

  #def reinit(car, passengers)
  #  @car = car
  #  @passengers = passengers
  #  size (@car.width+1)*@seat_size/2.0,
  #       (@car.height+1)*@seat_size/2.0
  #end

  def setup
    size (@car.width+1)*@seat_size/2.0,
         (@car.height+1)*@seat_size/2.0
    background 255
    smooth
  end
  
  def draw
    @car.plan.each_with_index do |col, col_num|
      col and col.each_with_index do |record, row_num|
        x = col_num*@seat_size/2.0
        y = row_num*@seat_size/2.0
          
        # clear background
        if (col_num.even? && row_num.even?)
          fill 255, 255, 255
          rect(x, y, @seat_size, @seat_size)
        end
        if record
          if record.pole > 0 # Stanchion
            fill 102, 255, 18
            rect(*space_to_xy(col_num, row_num),
                 @seat_size/4,
                 @seat_size/4)
          elsif record.position > 0 # Seat
            fill 255, 102, 18
            rect(x, y, @seat_size, @seat_size)

            if record.seat_pole > 0
              fill 102, 255, 18
              rect(*space_to_xy(col_num, row_num),
                   @seat_size/4,
                   @seat_size/4)
            end
          end
          fill 0, 0, 0
          f = createFont("Arial",16,true)
          textFont(f, 11)
          text(record.space, x, y+@seat_size)
        end
      end
    end
    draw_passengers(@passengers_by_stop[@stop])

  end
  def key_pressed
    puts "key_pressed: "+[key, keyCode].inspect
    if key == CODED
      case keyCode
      when 37 # <
      @stop = [@stop - 1, 0].max
      #when 38 # ^
      when 39 # >
      @stop = [@stop + 1, @passengers_by_stop.size - 1].min
      #when 40 # v
      end
    end
  end

  def space_to_xy(col, row)
    scale = @seat_size/2.0
    offset = (3/8.0)*@seat_size
    [col*scale + offset,
     row*scale + offset]
     
  end

  def draw_passengers(passengers)
    fill 18, 102, 255
    passengers.each do |passenger|
      col, row = parse_space(passenger.space)
      ellipse(*space_to_xy(col, row), @seat_size/2.0, @seat_size/2.0)
    end
  end
end

def main
  db_dir = '/Users/dgopstein/nyu/subway/db/'
  ci = CarImporter.new(db_dir+'LOOKUP_TBL.csv')
  si = StopImporter.new(db_dir+'FORM_TBL.csv')
  pi = PassengerImporter.new(db_dir+'RECORDS.csv')

  stops = si.stops.select{|s| s.car_class.starts_with?('R160')}

  car_vis = CarVisualizer.new(ci.cars['R160b'], [[]])

  [car_vis, si, pi, trips]
end
