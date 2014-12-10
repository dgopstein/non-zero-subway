# jruby --2.0 -S irb

require 'pp'

DB_DIR = '/Users/dgopstein/nyu/subway/db/'

def ci; $ci ||= CarImporter.new(DB_DIR+'LOOKUP_TBL.csv'); end
def si; $si ||= StopImporter.new(DB_DIR+'FORM_TBL.csv'); end
def pi; $pi ||= PassengerImporter.new(DB_DIR+'RECORDS.csv'); end

def main
  stops = si.stops.select{|s| s.car_class.starts_with?('R160')}

  #car_vis = CarVisualizer.new(ci.cars['R160b'], [[]])
  car_vis = CarVisualizer.new(ci.cars['R32'], [[]])

  [car_vis, ci, si, pi]
end

def with_time(&block)
  start = Time.now
  res = block[]
  stop = Time.now

  [res, stop - start]
end

def time(desc = 'block', &block)
  res, time = with_time(&block)

  puts "#{desc} took: #{time*1000}ms"

  res
end

def all_stops_passengers
  passengers_by_form_id = pi.by_stop
  stops_by_id = si.by_id

  passengers_by_form_id.map_keys{|k| stops_by_id[k]}
end

# The probability that a certain type of seat (seat by door, middle seat, standing by stanchion)
# will be occupied at any given time
# normalized by load factor
def stats_by_type(stops_pass = all_stops_passengers)
  stops = stops_pass.keys
  passengers = stops_pass.values.flatten
  stats = passengers.each_with_object(Hash.new{0}) do |pass, stats|
    stop = stops.find{|s| s.id == pass.form_id}
    car = ci.cars[stop.car_class]
    type = space_type(pass.space, car)

    stats[type] += 1
  end

  totals = stops.each_with_object(Hash.new{0}) do |stop, totals|
    car = ci.cars[stop.car_class]
    car.spaces.each do |space|
      type = space_type(space.ergo.space, car)
      totals[type] += 1
    end
  end
  
  rates = stats.reject{|k, v| k == :unknown}.deep_zip(totals).map_values{|(stat, tot)| stat.to_f / tot}
  normalize(rates)
end

# make all the values sum to 1
def normalize(hash)
  sum = hash.deep_inject(0){|s, (k, v)| s + v}
  
  hash.deep_map_values{|k| k / sum}
end

# eulcidean distance between two vectors (arrays of numbers)
def euclidean_distance(v1, v2)
  raise "vectors are different sizes!\n#{v1}\n#{v2}" if v1.size != v2.size

  Math.sqrt(v1.zip(v2).map{|a, b| ((b||0) - (a||0))**2}.sum)
end

def hash_distance(h1, h2)
  pairwise = h1.deep_zip(h2).deep_values # this returns a flat array, not a list of tuples

  a1, a2 = pairwise.each_with_index.partition{|v, i| i.even?}.map{|a| a.map(&:first)}

  euclidean_distance(a1, a2)
end

def occupied_and_not(plan, passengers)
  occupied = passengers.map(&:space)
  unoccupied = plan.flatten.select{|space| space and !occupied.include?(space.space)}

  [occupied, unoccupied]
end

# Simulate how passengers would fill a train if they behaved randomly
def choose_randomly(door, plan, passengers)
  occupied, unoccupied = occupied_and_not(plan, passengers)
  unoccupied.sample
end

# Go to the closest available seat
def choose_nearest(door, plan, passengers)
  occupied, unoccupied = occupied_and_not(plan, passengers)
  
  unoccupied.min_by { |s| manhattan_distance(door, s) }
end

# Go furthest from all people: 12seconds, 0.3682distance
def choose_alonest(door, plan, passengers)
  occupied, unoccupied = occupied_and_not(plan, passengers)
  
  unoccupied.max_by do  |space|
    nearest_person =
        occupied.min_by {|occ| manhattan_distance(space, occ)} ||
        choose_nearest(door, plan, passengers) # The first person will sit near the door
    
    manhattan_distance(nearest_person, space) 
  end
end

# Go far from people, but don't walk to far 8seconds
# [0.2932] - p.to_f/(1+d)
# [0.2958] - (p > 1 ? 10 : 1).to_f / (1 + d)
# [0.3183] - p.to_f/(1+d/5.0)
# [0.2758] - p.to_f/(1+d*2.0)
# [0.2743] - p.to_f/(1+d*5)
def choose_near_and_alone(door, plan, passengers)
  occupied, unoccupied = occupied_and_not(plan, passengers)

  nobody_near = plan.length # car is empty
  
  distance_to_people = 
    unoccupied.map do |space|
      occupied.map{|occ| manhattan_distance(space, occ)}.min || nobody_near
    end

  distance_to_door = unoccupied.map { |space| manhattan_distance(space, door) }

  weights =
    distance_to_people.zip(distance_to_door).map do |p, d|
      p.to_f/(1+d*5)
    end

  space_weights = Hash[*unoccupied.zip(weights).flatten]

  sample_weighted_hash(space_weights)
end

# [0.1315]
def choose_nearest_seat(door, plan, passengers)
  occupied, unoccupied = occupied_and_not(plan, passengers)
  
  nearest_seat = unoccupied.select(&:seat?).min_by { |s| manhattan_distance(door, s) }

  # Choose to stand if there are no seats
  if nearest_seat
    nearest_seat
  else
    unoccupied.min_by{|s| manhattan_distance(door, s)}
  end
end

def class_to_car(car_class)
  $ci.cars[car_class]
end

# A fully comprehensive pure strategy
# 22,8,14,1,5,4,1: [0.0790]
# 22,8,14,1,5,4,20: [0.0580]
# 22,8,14,1,5,4,10: [0.0579]
# 22,8,14,1,5,4,6: [0.0574]
# 22,8,14,1,5,4,3: [0.0355]
# 22,8,14,1,5,4,2: [0.0190] *
# 22,8,14,1,5,4,1: [0.0673]
DefaultType = {
  person: 22,
  dist: 14,
  seat: 8, 
  door: 5,
  seatpole: 4,
  nook: 2,
  anchor: 1
}

def space_cost(space_values_algo, type, plan, occupied, door, space)
  values = space_values_algo.call(plan, occupied, door, space)
  vals_weights = values.deep_zip(type)

  vals_weights.values.map{|v, w| v * w}.sum
end

Near_seat_alone_values = lambda do |plan, occupied, door, space|
  max_dist = 14.0
  car_dist = manhattan_distance('01a', plan.last.last)
  exp_dist = lambda do |a, b|
    [max_dist - longitudinal_distance(a, b), 0].max / max_dist
  end

  person_dist = if occupied.empty? then 1.0
                else Math.log(occupied.map{|occ| manhattan_distance(space, occ)}.min) / Math.log(car_dist)
                end
  sit_preference = space.seat? ? 1 : 0
  walk_distance = exp_dist.call(space, door)

  is_space_type = lambda{|type| space_type(space, class_to_car(space.car_class)) == type ? 1 : 0}

  anchor = 1 - is_space_type.call(:floor)
  stand_door = is_space_type.call(:floor_door)
  seatpole = is_space_type.call(:seatpole)
  nook = is_space_type.call(:seat_nook)

  {
    person: person_dist,
    dist: walk_distance,
    seat: sit_preference,
    door: stand_door,
    seatpole: seatpole,
    nook: nook,
    anchor: anchor
  }
end

def choose_near_seat_alone(door, plan, passengers, type = DefaultType)
  occupied, unoccupied = occupied_and_not(plan, passengers)
  weights = 
    unoccupied.map do |space|
      space_cost(Near_seat_alone_values, type, plan, occupied, door, space)
    end

  space_weights = Hash[*unoccupied.zip(weights).flatten]
  #p space_weights.map_keys(&:space)

  space_weights.max_by(&:last).first
end

def survey_objective
  %w(person dist) # facing_wall
  %w(stand dist)
  %w(person stand)
  %w(dist)
  %w(dist sit)
  %w(sit dist) # facing_forward
  %w(person sit)
  %w(person sit)
  %w(person)
  %w(person stand) # leg_room
  %w(dist person stand)
  %w(stand person)
end

# given a list of numbers, sample the list with frequencies
# proportional to those numbers, returning the index of the
# element selected
def sample_weighted_list(list)
  total = list.sum

  random = rand * total

  index = nil;

  list.each_with_index.inject(0) do |sum, (elem, i)|
    newsum = sum + elem

    if newsum >= random
      index = i
      break
    end
      
    newsum
  end

  index
end

# Given a hash of {:element => probability_of_selection}
# Select a key with probability proportional to its value
def sample_weighted_hash(hash)
  keys, vals = hash.to_a.transpose
  
  keys[sample_weighted_list(vals)]
end

def simulate_stop(car, stop, choice_algo)
  passengers_per_stop = 31 # average number of passengers per stop

  passengers = []

  doors = car.doors.select{|d| d.space[-1] == 'a'} # only doors facing one direction
  (0..passengers_per_stop).each do |i|
    door = doors[i % doors.length]
    space = choice_algo.call(door, car.plan, passengers)
    space_name = space_to_str(space)
    passengers << Passenger.new(i, stop.id, nil, space_name, nil, nil, nil).tap{|p| p.door = door}
  end

  [stop, passengers]
end

def simulate_algo(stops, method_name)
  stops.mash do |stop|
    car = ci.cars[stop.car_class]
    simulate_stop(car, stop, method(method_name))
  end
end

# For a list of multiple trips, boil it down to a list of 1-stop trips
# where the train travels just between 2 stations
# [[last_stop, this_stop], [this_stop, next_stop], ...]
def extract_stop_pairs(trips)
  trips.values.flatten(1).map{|trip| trip.each_cons(2)}.map(&:to_a).flatten(1)
end

# Given stop adjacent stops, determine (probabilistically)
# which passengers stay on, and which leave
def exit_passengers(last_stop, this_stop)
  last_passes = pi.by_stop[last_stop.id]
  this_passes = pi.by_stop[this_stop.id]

  this_hash = this_passes.mash{|pass| [pass.space, pass]}
  still_filled = last_passes.each_with_object({}) do |pass, h|
    this_pass = this_hash[pass.space]
    if this_pass
        h[pass.space] = [pass, this_pass]
    end
  end
 
  # The people who left who's seats weren't immediately refilled
  n_unreplaced = last_passes.size - still_filled.size

  # if the gender of a passenger changes, its probably two
  # separate people, changing places.
  same_gendered = still_filled.reject{|s, (p1, p2)| p1.gender != p2.gender}.values.map(&:first)
  
  # How many people switched gender at this stop
  n_gendered_replacements = still_filled.size - same_gendered.size

  # On average, just as many women will be replaced with women
  # as will be replaced with men, so multiply W->M * 2 to account for W->W
  # however, we can't know which seats were vacated, so just forget about it
  same_gendered
end

def simulate_trips(trips, method_name)
  stop_pairs = extract_stop_pairs(trips)

  stop_pairs.mash do |last_stop, this_stop|
    if last_stop.car_class.chop != this_stop.car_class.chop
      raise "cars aren't the same!:\n#{last_stop}\n#{this_stop}" 
    end

    car = ci.cars[last_stop.car_class]
    remaining_passengers = exit_passengers(last_stop, this_stop)
    n_boarding = pi.by_stop[this_stop.id].size - remaining_passengers.size
    simulate_trip_stop(car, last_stop, remaining_passengers,
                       n_boarding, method(method_name))
  end
end

def space_to_str(space)
  space.is_a?(String) ? space : space.space
end

def space_to_obj(space)
  #space.is_a?(String) ? $si.byspace : space
end

def simulate_trip_stop(car, stop, passengers, n_boarding, choice_algo)
  new_passengers = passengers.dup
  stop_id = if stop.nil? || Fixnum === stop then stop else stop.id end
  door_row = stop_id.even? ? 'a' : ('a'..'z').to_a[car.height - 1]

  doors = car.doors.select{|d| d.space[-1] == door_row} # only doors facing one direction

  (0...n_boarding).each do |i|
    door = doors[i % doors.length]
    space = choice_algo.call(door, car.plan, new_passengers)
    space_name = space_to_str(space)
    new_passengers << Passenger.new(i, stop_id, nil, space_name, nil, nil, nil).tap{|p| p.door = door}
  end

  [stop, new_passengers]
end

#TODO visualize decision weights per passenger
#TODO every stop, present real seating scenerio along trips
#TODO more accurate doors, longitudenally & laterally

# compare different space choosing algorithms
def compare_algos
  control_data = all_stops_passengers
  control_stats = stats_by_type(control_data)
  stop_passes_list = {
    control: ->{ control_data },
    women: ->{ control_data.deep_select{|pass| pass.gender == 'F' } },
    men: ->{ control_data.deep_select{|pass| pass.gender == 'M' } },
    random:  ->{ simulate_algo(si.stops, :choose_randomly) },
    #alonest: ->{ simulate_algo(si.stops, :choose_alonest) },
    #near_and_alone: ->{ simulate_algo(si.stops, :choose_near_and_alone) },
    #nearest_seat: ->{ simulate_algo(si.stops, :choose_nearest_seat) },
    #near_seat_alone: ->{ simulate_algo(si.stops, :choose_near_seat_alone) },
    trip_nearest_seat: ->{ simulate_trips(si.trips, :choose_nearest_seat) }, # [0.1516]
    trip_seat_alone: ->{ simulate_trips(si.trips, :choose_near_seat_alone) },
  }

  res = stop_passes_list.mash do |name, algo|
    stop_passes = time(name, &algo)
    stats = stats_by_type(stop_passes)
    dist = hash_distance(control_stats, stats)
    display_stats = stats.map_values{|v| '%.03f' % v}.sort_by{|k,v|k}
    puts '[%.04f] %10s - %s' % [dist, name, display_stats]
    [name, stop_passes]
  end

  #display_alternating(res[:control], res[:trip_seat_alone])
  #display_passengers(res[:trip_seat_alone])
  #display_passengers(res[:nearest_seat])
  #display_heatmap(res[:control])
  #display_heatmap(res[:trip_seat_alone])

  #$algo = :control
  #$algo = :random
  $algo = :men
  display_heatmap(res[$algo])

  nil
end

def display_alternating(hash_a, hash_b)
  flat_hash = hash_a.keys.inject({}) do |h, k|
    kb = k.dup
    kb.id = k.id.to_s+'b'
    a = hash_a[k]
    b = hash_b[k]
    if (a && b)
      h.merge(k => a, kb => b)
    else
      h
    end
  end
  #pp flat_hash.deep_map{|k, v| 'p'+v.ergo.space.to_s}.map_keys{|k| 's'+k.id.to_s}
  $cv ||= CarVisualizer.new()
  $cv.play_stops(flat_hash)
end

def display_passengers(hash)
  $cv ||= CarVisualizer.new()
  $cv.play_passengers(hash)
end

def display_heatmap(hash)
  $cv ||= CarVisualizer.new()
  car_name = 'R68'
  single_car = hash.select{|k,v| k.car_class == car_name}
  $cv.draw_heatmap(single_car, "heatmap_#{car_name}_#{$algo}.png")
end

def run_inspector
  $cv ||= CarInspector.new(method(:choose_near_seat_alone), DefaultType)
  $cv.play_sim()
end
