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
def distance(v1, v2)
  raise "vectors are different sizes!\n#{v1}\n#{v2}" if v1.size != v2.size

  Math.sqrt(v1.zip(v2).map{|a, b| ((b||0) - (a||0))**2}.sum)
end

def hash_distance(h1, h2)
  pairwise = h1.deep_zip(h2).deep_values # this returns a flat array, not a list of tuples

  a1, a2 = pairwise.each_with_index.partition{|v, i| i.even?}.map{|a| a.map(&:first)}

  distance(a1, a2)
end

def occupied_and_not(plan, passengers)
  occupied = passengers.map(&:space)
  unoccupied = plan.flatten.select{|space| space and !occupied.include?(space)}

  [occupied, unoccupied]
end

# Simulate how passengers would fill a train if they behaved randomly
def choose_randomly(door, plan, passengers)
  occupied, unoccupied = occupied_and_not(plan, passengers)
  unoccupied.sample
end

def space_distance(s1, s2)
  c1, r1 = parse_space(s1)
  c2, r2 = parse_space(s2)

  (c2 - c1).abs + (r2 - r1).abs
end

# Go to the closest available seat
def choose_nearest(door, plan, passengers)
  occupied, unoccupied = occupied_and_not(plan, passengers)
  
  unoccupied.min_by { |s| space_distance(door, s) }
end

def simulate_stop(car, stop, choice_algo)
  passengers_per_stop = 20

  passengers = []

  doors = car.doors.select{|d| d.space[-1] == 'a'} # only doors facing one direction
  (0..passengers_per_stop).each do |i|
    space = choice_algo.call(doors[i % doors.length], car.plan, passengers)
    passengers << Passenger.new(i, stop.id, nil, space, nil, nil, nil)
  end

  [stop, passengers]
end

def simulate_algo(stops, method_name)
  stops.mash do |stop|
    car = ci.cars[stop.car_class]
    simulate_stop(car, stop, method(method_name))
  end
end


# compare different space choosing algorithms
def compare_algos
  control_data = all_stops_passengers
  control_stats = stats_by_type(control_data)
  stop_passes_list = {
    control: control_data,
    random: simulate_algo(si.stops, :choose_randomly),
    nearest: simulate_algo(si.stops, :choose_nearest),
  }

  stop_passes_list.each do |name, stop_passes|
    stats = stats_by_type(stop_passes)
    dist = hash_distance(control_stats, stats)
    display_stats = stats.map_values{|v| '%.03f' % v}.sort_by{|k,v|k}
    puts '[%.04f] %10s - %s' % [dist, name, display_stats]
  end

  nil
end
