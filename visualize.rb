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
orange = #ffa13d


class CarVisualizer < Processing::App
  include Heatmaps

  attr_accessor :passengers_by_stop, :stop, :car

  def dir
    File.dirname(File.expand_path(".", __FILE__))
  end

  def useHSB(&block)
    colorMode(HSB, 100)
    block.call
    colorMode(RGB, 255)
  end

  def seat_size
    case car.name
    #when 'R68_section' then 42
    when 'R68' then 42
    else 40
    end
  end

  def set_car(c)
    @car = c
  end

  def initialize(passengers_by_stop = {}, car_name = 'R68')
    @stop_idx = 0
    @passengers_by_stop = passengers_by_stop
    @heatmap = nil

    @car = ci.cars[
      passengers_by_stop.empty? ? car_name : stops.first.car_class
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

  def vtext(text, x, y)
    pushMatrix();
    translate(x,y);
    rotate(-HALF_PI);
    text(text,0,0);
    popMatrix();
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

            if record.seatpole > 0
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
    centering_offset = (3/8.0)*seat_size # draw the circles in the middle of the seats
    hs = (1/2.0)*seat_size 
    margin = seat_size+3
    transverse_legroom = 25
    x = y = 0
    if car.name == 'R68_section'
      xss = seat_size.to_f + 1
      yss = seat_size.to_f - 1
      x = -hs +
        case col
        when 1 then 2*xss
        when 2 then 3*xss
        when 3 then 4*xss
        when 4 then 5*xss
        when 5 then 6*xss
        when 6 then 7*xss
        when 7 then 8*xss
        when 8 then 9*xss + transverse_legroom
        else 1000
        end
      y = -hs-2 + margin +
        case row
        when 0 then yss
        when 1 then 2*yss
        when 2 then 3*yss
        when 3 then 4*yss
        when 4 then 5*yss + 1
        when 5 then 6*yss + 1
        else 1000
        end
    elsif car.name == 'R68'
      y_scale = seat_size - 2
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

  def draw_passenger(space)
    col, row = parse_space(space)
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

      trail_weight = 75

      stroke(64)
      door_row, door_col = parse_space(door_space)
      door_x, door_y = space_to_xy(door_row, door_col)
      x, y = space_to_xy(col, row)

      top_weight = car.top?(row) ? 1 : -1
      side_offset = trail_weight * top_weight
      circle_offset = seat_size / 4.0 * top_weight

      door_top_weight = car.top?(door_col) ? 1 : -1
      door_offset = trail_weight * door_top_weight
      door_circle_offset = -seat_size / 4.0 * door_top_weight

      door_x_jitter = (13 * col + 7 * row + 3) % 23

      bezier(x, y + circle_offset,
             x, y + side_offset,
             door_x, door_y + door_offset,
             door_x + door_x_jitter, door_y + door_circle_offset)
  end

  def draw_trails(passengers)
    passengers.ergo.each do |passenger|
      col, row = parse_space(passenger.space)

      # draw trail
      noFill
      draw_trail_pretty(col, row, passenger.door.space) if passenger.door
    end
  end

  def draw_passengers(passengers)
    passengers.ergo.each do |passenger|
      col, row = parse_space(passenger.space)

      fill(*PassengerColor)
      draw_passenger(passenger.space)
    end
  end

  def draw_future_costs(future_costs)
    useHSB do
      min_cost = future_costs.values.min
      max_cost = future_costs.values.max
      cost_range = max_cost - min_cost
      scale_cost = lambda{|cost| (cost - min_cost) / cost_range.to_f}
      @all_future_costs.each do |space, cost|
        cost_scaled = scale_cost[cost]
        x, y = space_to_xy(*space.col_row).map{|n| n - seat_size/2.0}
        
        # squares
        purp = [254.0 / 3.6, 17* (5**cost_scaled - 1)]
        #yellow = [59.0 / 3.6, 50* (4**cost_scaled - 1)]
        #orange = [46 / 3.6, 80* (4**cost_scaled - 1)]
        fill(*purp, 100)

        rsize = seat_size * 0.7
        roff = (seat_size - rsize) / 2.0
        rect(x + roff, y + roff, rsize, rsize, 8)

        # numbers
        fill(0)
        textAlign(RIGHT)
        textSize(12)
        #p [x, y, seat_size] if space.space == '01a'
        text('%2.0f'%cost, x + 30, y + seat_size / 2.0 + 5)
      end
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

ValuesHeight = 250
CostHeight = 250

class CarInspector < CarVisualizer
  attr_accessor :choice_algo, :value_algo, :type, :history, :passengers, :user_space
  def initialize(choice_algo, value_algo, type)
    super({}, car_name = 'R68_section')
    @choice_algo = choice_algo
    @value_algo = value_algo
    @original_type = type.dup
    @type = type.dup
    @history = []
    @passengers = []
    @stop_id = 0
  end

  def setup
    clear
    @size_x = (@car.width+2)*seat_size
    @size_y = (@car.height+2)*seat_size + ValuesHeight + CostHeight
    size @size_x, @size_y
    smooth
  end

  def col_row_to_str(col, row)
    (col+1).to_s + ('a' .. 'z').to_a[row]
  end

  def simulate_stop
    _, @passengers = simulate_trip_stop(car, @stop_id, @passengers, n_boarding = 1, choice_algo)
    @stop_id += 1

    @history << @passengers
  end

  def play_sim
  end

  def max_cost
    @max_cost ||= type.values.sum
  end

  def draw_costs(costs)
    origin_x = 40
    origin_y = 600
    clear_rect(origin_x - 50 , origin_y - 20, 500, 600)

    plot_offset_y = 150
    text_offset_y = 170

    # draw x-axis labels, cost numbers
    x_inc = 20
    x_offset = -15
    costs.each do |cost|
      fill(0)
      textSize(11)
      text('%2.0f' % cost, origin_x + x_offset + 25, origin_y + text_offset_y)

      x_offset += x_inc
    end

    # draw sum cost
    sum_cost =
      if @passengers.size < costs.size
        costs.drop(@passengers.size).sum
      else
        costs.sum
      end
    textSize(20)
    text('%2.0f' % sum_cost, origin_x + 185, origin_y + text_offset_y - 40)

    x_offset = -15

    # draw current x cursor
    stroke(200, 50, 50)
    strokeWeight(2)
    cursor_x = origin_x + x_offset + x_inc * @passengers.size
    line(cursor_x, origin_y + plot_offset_y, cursor_x, origin_y + plot_offset_y - 150) if @costs

    #max_cost = (costs.max || 45)
    min_cost = 20 # completely arbitrary
    scale_display = 200
    cost_range = max_cost - min_cost
    scale_cost = lambda{|cost| (cost - min_cost) / cost_range.to_f}
    # draw line plot
    noFill();
    stroke(0);
    beginShape();
    curveVertex(origin_x + x_offset, origin_y + plot_offset_y - scale_display*scale_cost.call(costs.first || max_cost))
    costs.each do |cost|
      x_offset += x_inc
      curveVertex(origin_x + x_offset, origin_y + plot_offset_y - scale_display*scale_cost.call(cost))
    end
    curveVertex(origin_x + x_offset+1, origin_y + plot_offset_y - scale_display*scale_cost.call(costs.last||max_cost))
    curveVertex(origin_x + x_offset+2, origin_y + plot_offset_y - scale_display*scale_cost.call(costs.last||max_cost))
    endShape();
    strokeWeight(1)

  end

  def clear_rect(x, y, w, h)
    fill(255)
    stroke(255)
    rect(x, y, w, h)
  end

  ValuesBottom = 490
  ValuesTop = 340
  WeightPad = 4
  BarHeight = ValuesBottom - ValuesTop
  def max_weight
    type.values.max.to_f
  end

  def draw_user_values(vals)
    origin_x = 40
    origin_y = ValuesBottom

    bar_width = 35
    bar_height = -BarHeight

    pad = WeightPad

    x_offset = 0
    x_inc = 1.5 * bar_width

    # blank words
    clear_rect(origin_x - 2*pad, origin_y + 1, 600, 70)
    textAlign(RIGHT)

    type.deep_zip(vals).map do |key, (weight, val)|
      weight_fract = weight / max_weight

      box_height = bar_height * weight_fract - pad

      # weight
      noFill
      stroke(0)
      rect(origin_x + x_offset, origin_y, bar_width, box_height)

      # value
      fill(*UserColor)
      rect(origin_x + x_offset + pad, origin_y, bar_width - 2*pad, bar_height * weight_fract * val)

      # name
      fill(0)
      textSize(16)
      vtext(key.to_s, origin_x + x_offset + 20, origin_y + 10)

      x_offset += x_inc
    end

  end

  def draw
    #clear_rect(0, 0, @size_x, @size_y)
    draw_pretty_car(car)
    draw_trails(@passengers)
    draw_future_costs(@all_future_costs) if @all_future_costs && !@all_future_costs.empty?
    draw_passengers(@passengers)
    fill(*UserColor)
    draw_passenger(@user_space) if @user_space
    draw_user_values(@user_space_values) if @user_space_values
    draw_costs(@costs || [])
  end

  def key_pressed(event)
    case event.keyChar
    when 32
      @type = @original_type.dup
    end
    case event.keyCode
      when 37 # <
        @history.pop
        @passengers = @history.last || []
        @user_space = nil if @user_space && !@passengers.map(&:space).include?(@user_space.space)
        #p @user_space
        reset_space_values

      when 39 # >
        simulate_stop if @passengers.size < car.spaces.compact.size
        reset_space_values
        #puts "done simulating"

      when 38 # ^
        @all_future_costs = all_future_costs(value_algo, choice_algo, @passengers, 18)

      when 40 # v
        @all_future_costs = []
    end
  end

  def mousePressed
    if mouseY < ValuesTop
      col_row = xy_to_space_pretty(mouseX, mouseY)
      if col_row.all?
        space = col_row_to_space(col_row)
        @user_space = space
        pass = Passenger.new(0, @stop_id, nil, @user_space.space, nil, nil, nil).tap{ |pa| pa.door = car.nearest_door(pa) }
        @user_pass = pass
        if !@passengers.map(&:space).include?(space.space)
          @passengers = (passengers + [pass])
          @history << @passengers
        end
      else
        @user_space = nil
      end
      reset_space_values
    elsif mouseY < ValuesBottom # User tries to grab type
      body_width = @size_x - 2*seat_size
      slider_width = body_width / type.size.to_f
      body_x = mouseX - seat_size
      type_index = body_x / slider_width.floor

      update_type(type_index, mouseY)
    end
  end

      #weight_fract = weight / max_weight
      #box_height = bar_height * weight_fract - pad

      #weight_fract = (box_height + pad) / bar_height
      #weight = max_weight / weight_fract
  def update_type(type_index, mouseY)
    h_key = type.keys[type_index]
    new_height = ValuesBottom - mouseY 

    weight_fract = (new_height + WeightPad) / BarHeight.to_f
    weight = max_weight * weight_fract
    new_weight = [weight, max_weight].min # don't nerf the other weights

    clear_rect(0, ValuesTop, @size_x, BarHeight)

    type.merge!(h_key => new_weight).tap{|t| puts "type: #{t.map_values{|x| x.round(1)}.inspect}"}
  end

  def str_to_space(str, car=@car)
    c, r = parse_space(str)
    car.plan[c][r]
  end

  def col_row_to_space(col_row, car=@car)
    car.plan[col_row[0]][col_row[1]]
  end

  def triangle_map(a); (1 .. a.size).map{|i| a[0,i] }; end

  def historical_costs(pre_all_passengers, space_str)
    space =
      if space_str.is_a?(String)
        str_to_space(space_str)
      else
        space_str
      end

    all_passengers = reject_space(pre_all_passengers, space)

    triangle_map(all_passengers).map do |passengers|
      values = value_algo.call(car.plan, passengers, car.nearest_door(space), space)
      values.deep_zip(type).values.map{|v, w| v * w}.sum
    end
  end

  def all_future_costs(value_algo, choice_algo, passengers, total_borders)
    occupied, unoccupied = occupied_and_not(car.plan, passengers)

    puts
    unoccupied.each_with_index.mash do |space, i|
      future_values = predict_future(value_algo, choice_algo, space, passengers, 18)
      sum = future_values.drop(@passengers.length).sum
      Kernel.print ["\r[", *i.times.map{'.'}, ']'].join
      [space, sum]
    end.tap{ puts }
  end

  def predict_future(value_algo, choice_algo, user_pass, passes, total_borders) 
    stop_id = @stop_id
    space = user_pass.space
    future_passes =
        simulate_trip_stop(car, stop_id, @passengers||[], (total_borders - @passengers.size), choice_algo)[1]

    historical_costs(future_passes, space)
  end

  def reject_space(passes, space)
    space_str = space && !space.is_a?(String) ? space.space : space
    passes.dup.tap do |pas|
      pas.reject!{|pa| pa.space == space_str}
    end
  end

  def reset_space_values
    passes = reject_space(@passengers, @user_space)
    if @user_space
      @user_space_values = value_algo.call(car.plan, passes, car.nearest_door(@user_space), @user_space)
      @costs = predict_future(value_algo, choice_algo, @user_pass, passes, 18)
      clear
    end
  end
end
