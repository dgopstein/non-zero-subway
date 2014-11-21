require 'ruby-processing'
require '/Users/dgopstein/ruby-processing-heatmaps-lib/heatmaps.rb'

Processing::App::SKETCH_PATH = __FILE__

class CarVisualizer < Processing::App
  include Heatmaps

  attr_accessor :passengers_by_stop, :stop, :car

  def set_car(c)
    @car = c

    # pretty sure this doesn't do anything
    resize (@car.width+1)*@seat_size,
         (@car.height+1)*@seat_size
  end

  def initialize(passengers_by_stop = {})
    @seat_size = 40
    @stop_idx = 0
    @passengers_by_stop = passengers_by_stop
    @heatmap = nil

    @car = $ci.cars[
      passengers_by_stop.empty? ? 'R68' : stops.first.car_class
    ]

    super(x: 40, y: 30) # what does this mean?
  end

  # {Stop => [Passenger]}
  def play_stops(stops_passes)
    @passengers_by_stop = stops_passes
  end

  # {Stop => [Passenger]}
  def play_passengers(stops_passes)
    suffixes = ('aa'..'zz').take(200)
    @passengers_by_stop = stops_passes.inject({}) do |h, (stop, pass)|
      pass_by_stop = (0..pass.length).mash do |i|
        stop_suffix = suffixes[i]
        new_stop = stop.dup.tap{|s| s.id = s.id.to_s+stop_suffix }
        new_passes = pass[0, i]
        [new_stop, new_passes]
      end
      h.merge(pass_by_stop)
    end
  end

  #def reinit(car, passengers)
  #  @car = car
  #  @passengers = passengers
  #  size (@car.width+1)*@seat_size/2.0,
  #       (@car.height+1)*@seat_size/2.0
  #end

  def setup
    background 255
    size (@car.width+1)*@seat_size,
         (@car.height+1)*@seat_size
    smooth
  end
  
  def draw
    car.plan.each_with_index do |col, col_num|
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
          text(space_type(record.space, car).to_s.gsub(/.*_/, ''), x, y+@seat_size)
        end
      end
    end
    draw_passengers(@passengers_by_stop.values[@stop_idx])

    image(@heatmap, 0,0) if @heatmap
  end

  def key_pressed
    #puts "key_pressed: "+[key, keyCode].inspect
    if key == CODED
      case keyCode

      when 37 # <
      @stop_idx = [@stop_idx - 1, 0].max
      set_car $ci.cars[stop.car_class]
      puts "stop: "+ stop.id.to_s

      when 39 # >
      @stop_idx = [@stop_idx + 1, @passengers_by_stop.size - 1].min
      set_car $ci.cars[stop.car_class]
      puts "stop: "+ stop.id.to_s

      #when 38 # ^
      #when 40 # v
      end
    end
  end
  
  def stop
    @passengers_by_stop.keys[@stop_idx]
  end

  def passengers
    @passengers_by_stop.values[@stop_idx]
  end

  def space_to_xy(col, row)
    scale = @seat_size
    offset = (3/8.0)*@seat_size
    [col*scale + offset,
     row*scale + offset].map(&:to_i)
  end

  def draw_passengers(passengers)
    fill 18, 102, 255
    passengers.ergo.each do |passenger|
      col, row = parse_space(passenger.space)
      ellipse(*space_to_xy(col, row), @seat_size/2.0, @seat_size/2.0)

      # draw trail
      if passenger.door
        door_col, door_row = parse_space(passenger.door.space)
        door_x, door_y = space_to_xy(door_col, door_row)
        door_y -= @seat_size/3.0
        line(door_x, door_y, *space_to_xy(col, row))
      end

    end
  end

  def draw_heatmap(passengers_by_stop)
    raise 'multiple car classes!' if passengers_by_stop.keys.map(&:car_class).uniq.size > 1

    car = $ci.cars[passengers_by_stop.keys.first.car_class]
    passengers = passengers_by_stop.values.flatten
    dots = passengers.map(&:space).map{|s| space_to_xy(*parse_space(s))}


    #(0..dots.length).each do |len|
      #len = 4
      len = dots.length
      @heatmap = 
      time("generating heatmap of len #{len}") do
        draw_heat(width, height, dots.take(len), @seat_size*2)
      end
    #end

  end
end
