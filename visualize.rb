require 'ruby-processing'
require '/Users/dgopstein/ruby-processing-heatmaps-lib/heatmaps.rb'

Processing::App::SKETCH_PATH = __FILE__

#http://www.colourlovers.com/palette/1930/cheer_up_emo_kid
#PassengerColor = [78,205,196]
#UserColor = [199,244,100]

#http://www.colourlovers.com/palette/46688/fresh_cut_day
#PassengerColor = [64,192,203]
PassengerColor = [0,168,198]
UserColor = [174,226,57]

$Arial12 = nil

#TODO try something maroon maybe?

class CarVisualizer < Processing::App
  include Heatmaps

  attr_accessor :passengers_by_stop, :stop, :car

  def dir
    File.dirname(File.expand_path(".", __FILE__))
  end

  def seat_size
    case car.name
    when 'R68' then 42
    else 40
    end
  end

  def set_car(c)
    @car = c
  end

  def initialize(passengers_by_stop = {})
    @stop_idx = 0
    @passengers_by_stop = passengers_by_stop
    @heatmap = nil

    @car = ci.cars[
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
  #  size (@car.width+1)*seat_size/2.0,
  #       (@car.height+1)*seat_size/2.0
  #end

  def setup
    clear
    size (@car.width+2)*seat_size,
         (@car.height+2)*seat_size
    smooth
  end

  def clear
    background 255
  end


  def draw_car(car)
    car.plan.each_with_index do |col, col_num|
      col and col.each_with_index do |record, row_num|
        x = col_num*seat_size
        y = row_num*seat_size
          
        # clear background
        fill 255, 255, 255
        rect(x, y, seat_size, seat_size)
        if record
          if record.pole > 0 # Stanchion
            fill 102, 255, 18
            rect(*space_to_xy(col_num, row_num),
                 seat_size/4,
                 seat_size/4)
          elsif record.position > 0 # Seat
            fill 255, 102, 18
            rect(x, y, seat_size, seat_size)

            if record.seat_pole > 0
              fill 102, 255, 18
              rect(*space_to_xy(col_num, row_num),
                   seat_size/4,
                   seat_size/4)
            end
          end
          fill 0, 0, 0
          f = createFont("Arial",16,true)
          textFont(f, 11)
          #text(record.space, x, y+seat_size)
          text(space_type(record.space, car).to_s.gsub(/.*_/, ''), x, y+seat_size)
        end
      end
    end
  end

  def draw_pretty_car(car)
    img = loadImage(dir+"/layout/layout_#{car.name}.png")
    tint(255, 127)
    image(img, seat_size, seat_size) # give the image a bit of a margin
  end

  def draw_plain
    draw_car(car)
    draw_passengers(@passengers_by_stop.values[@stop_idx])

    # overlay a heatmap if it exists
    image(@heatmap, 0,0) if @heatmap
  end

  def draw_pretty
    draw_pretty_car(car)
    draw_passengers(@passengers_by_stop.values[@stop_idx])

    # overlay a heatmap if it exists
    image(@heatmap, 0,0) if @heatmap

  end
  
  def draw
    #draw_plain
    draw_pretty
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

  def space_to_xy_plain(col, row)
    scale = seat_size
    offset = (3/8.0)*seat_size
    [col*scale + offset,
     row*scale + offset].map(&:to_i)
  end

  def space_to_xy_pretty(col, row)
    x = y = 0
    if car.name == 'R68'
      transverse_legroom = 25
      margin = seat_size+3
      y_scale = seat_size - 2
      centering_offset = (3/8.0)*seat_size # draw the circles in the middle of the seats
      y = row*y_scale + margin + centering_offset

      section_seats = 11 # width of a section in seats
      section_width = 462 # width of a section in pixels
      n_sections = col/section_seats # how many sections from the left the passengers is
      section_offset = col%section_seats # how far into the section they are in seats
      section_offset_width = seat_size * section_offset # how far into the section they are in pixels
      section_offset_width += transverse_legroom if section_offset > 7 # account for legroom
      section_offset_width -= (seat_size - 5) if section_offset > 8 # account for missing row
      section_offset_width += transverse_legroom if section_offset > 10 # account for legroom

      if (col == 41)
        section_offset_width -= 33 # end of car
      end

      x = n_sections * section_width + section_offset_width + centering_offset
    end

    [x, y].map(&:to_i)
  end

  def xy_to_space_pretty(x, y)
    rows = (0 ... car.height)
    cols = (0 ... car.width)

    col = cols.find{|c| r_x = space_to_xy_pretty(c, 0)[0]; (r_x - x).abs < seat_size/2}
    row = rows.find{|r| r_y = space_to_xy_pretty(0, r)[1]; (r_y - y).abs < seat_size/2}

    [col, row]
  end

  def space_to_xy(col, row)
    #space_to_xy_plain(col, row)
    space_to_xy_pretty(col, row)
  end

  def draw_passenger(col, row)
    passenger_size = seat_size / 1.8
    stroke(96)
    ellipse(*space_to_xy(col, row), passenger_size, passenger_size)
  end

  def draw_trail(col, row, door_space)
      door_col, door_row = parse_space(door_space)
      door_x, door_y = space_to_xy(door_col, door_row)
      door_y -= seat_size/3.0
      line(door_x, door_y, *space_to_xy(col, row))
  end

  def draw_trail_pretty(col, row, door_space)
      stroke(64)
      door_x, door_y = space_to_xy(*parse_space(door_space))
      door_y -= seat_size/3.0
      x, y = space_to_xy(col, row)

      is_top = row.to_f / car.height < 1.0/2 ? 1 : -1
      side_offset = 100 * is_top
      circle_offset = seat_size / 4.0 * is_top

      bezier(x, y + circle_offset, x, y + side_offset, door_x, door_y + 100, door_x, door_y)
  end

  def draw_passengers(passengers)
    passengers.ergo.each do |passenger|
      col, row = parse_space(passenger.space)

      fill(*PassengerColor)
      draw_passenger(col, row)

      # draw trail
      noFill
      draw_trail_pretty(col, row, passenger.door.space) if passenger.door
    end
  end

  def draw_heatmap(passengers_by_stop, filename=nil)
    raise 'multiple car classes!' if passengers_by_stop.keys.map(&:car_class).uniq.size > 1

    clear

    car = $ci.cars[passengers_by_stop.keys.first.car_class]
    passengers = passengers_by_stop.values.flatten
    dots = passengers.map(&:space).map{|s| space_to_xy(*parse_space(s))}


    #(0..dots.length).each do |len|
      #len = 4
      len = dots.length
      @heatmap = 
      time("generating heatmap of len #{len}") do
        draw_heat(width, height, dots.take(len), seat_size*2)
      end
    #end

    if filename && !filename.empty?
      puts "Saving image to #{filename}"
      sleep 1
      p save(dir+'/'+filename) 
    end
  end
end

class CarInspector < CarVisualizer
  attr_accessor :choice_algo, :type, :history, :passengers, :user_space
  def initialize(choice_algo, type)
    super()
    @choice_algo = choice_algo
    @type = type
    @history = []
    @passengers = []
  end

  def setup
    $Arial12 = createFont("Arial", 12, true )
    clear
    size (@car.width+2)*seat_size,
         (@car.height+2)*seat_size + 250
    smooth
  end

  def col_row_to_str(col, row)
    (col+1).to_s + ('a' .. 'z').to_a[row]
  end

  def simulate_stop
    @stop_id = (@stop_id || -1) + 1
    new_passengers = passengers.dup
    doors = car.doors.select{|d| d.space[-1] == 'a'} # only doors facing one direction
    n_boarding = 1 # + rand(30)
    (0...n_boarding).each do |i|
      door = doors[i % doors.length]
      # Don't let anybody sit on the user
      occupied = if @user_space 
          new_passengers + [Passenger.new(i, @stop_id, nil, col_row_to_str(*@user_space), nil, nil, nil)]
        else
          new_passengers
        end
      space = choice_algo.call(door, car.plan, occupied)
      space_name = space_to_str(space)
      new_passengers << Passenger.new(i, @stop_id, nil, space_name, nil, nil, nil).tap{|p| p.door = door}
    end
    @history << new_passengers
    @passengers = new_passengers
  end

  def play_sim
  end

  def draw_user_values(weights, vals)
    origin_x = 100
    origin_y = 500

    bar_width = 50
    bar_height = -150

    pad = 4

    max_weight = weights.values.max.to_f

    x_offset = 0

    # blank words
    fill(255)
    stroke(255)
    rect(origin_x - 2*pad, origin_y + 40, 600, -30)
    textAlign(CENTER)

    weights.deep_zip(vals).map do |key, (weight, val)|
      weight_fract = weight / max_weight

      # weight
      noFill
      stroke(0)
      rect(origin_x + x_offset, origin_y, bar_width, bar_height * weight_fract - pad)

      # value
      fill(98, 76, 54)
      rect(origin_x + x_offset + pad, origin_y, bar_width - 2*pad, bar_height * weight_fract * val)

      # name
      fill(76, 54, 98)
      textSize(14)
      text(key.to_s, origin_x + x_offset + 25, origin_y + 30)

      x_offset += 1.5 * bar_width
    end

  end

  def draw
    draw_pretty_car(car)
    draw_passengers(@passengers)
    fill(*UserColor)
    draw_passenger(*@user_space) if @user_space
    draw_user_values(DefaultType, @user_space_values) if @user_space_values
  end

  def key_pressed(event)
    case event.keyCode
      when 37 # <
        @history.pop
        @passengers = @history.last || []
        reset_space_values

      when 39 # >
        simulate_stop
        reset_space_values
        puts "done simulating"

      #when 38 # ^
      #when 40 # v
    end
  end

  def mousePressed
    col_row = xy_to_space_pretty(mouseX, mouseY)
    @user_space = col_row.all? ? col_row : nil
    reset_space_values
  end

  def col_row_to_space(col_row, car=ci.cars['R68'])
    car.plan[col_row[0]][col_row[1]]
  end

  def reset_space_values
    begin
      us = col_row_to_space(@user_space)
      @user_space_values = Near_seat_alone_values.call(car.plan, @passengers, us, us)
      clear
    rescue
      puts "#{@user_space.inspect} outside of car"
    end
  end
end
