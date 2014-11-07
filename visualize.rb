require 'ruby-processing'

Processing::App::SKETCH_PATH = __FILE__

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
    size (@car.width+1)*@seat_size,
         (@car.height+1)*@seat_size
    background 255
    smooth
  end
  
  def draw
    @car.plan.each_with_index do |col, col_num|
      col and col.each_with_index do |record, row_num|
        x = col_num*@seat_size
        y = row_num*@seat_size
          
        # clear background
        fill 255, 255, 255
        rect(x, y, @seat_size, @seat_size)
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
          #text(record.space, x, y+@seat_size)
          text(space_type(record.space, @car).to_s.gsub(/.*_/, ''), x, y+@seat_size)
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
    scale = @seat_size
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

