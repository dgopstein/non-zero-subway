require 'csv'

require 'csv_importer.rb'
require 'passenger.rb'

class Car
  attr_accessor :name, :plan, :lookup_tbl

  def initialize(name)
    @name = name
    @plan = []
    @lookup_tbl = {}
  end

  def height
    plan.map{|x| x.ergo.size || 0 }.max
  end

  def width
    plan.size
  end

  def spaces
    plan.flatten
  end
end

Space = Struct.new(:car_class, :space, :position, :pole, :wall, :door, :map, :legroom, :perpendicular, :seat_pole, :vestibule)

def parse_space(str)
  space_col, space_row = str.match(/([0-9.]+)(\w+)/).captures
  [space_col.to_i, (space_row.downcase.ord - 'a'.ord)]
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
      space = Space.new(*row.to_a)

      car.lookup_tbl[space.space] = space

      # split a spot description e.g., '10d' into its vertical and horizontal components, [10, d]
      space_col, space_row = parse_space(space.space)

      car_col = (car.plan[space_col] ||= [])

      car_col[space_row] = space
    end
  end
end

def space_type(space_name, car)
  space = car.lookup_tbl[space_name] or return :floor

  if space.position > 0
    if space.door > 0 then :seat_door
    elsif space.seat_pole > 0 then :seat_pole
    elsif space.wall > 0 then :seat_wall
    else :seat_middle
    end
  else
    if space.door > 0 then :floor_door
    elsif space.pole > 0 then :floor_pole # pole NOT seat_pole
    elsif space.wall > 0 then :floor_wall
    else :floor
    end
  end
end

DB_DIR = '/Users/dgopstein/nyu/subway/db/'

def importers
  [ci = CarImporter.new(DB_DIR+'LOOKUP_TBL.csv'),
  si = StopImporter.new(DB_DIR+'FORM_TBL.csv'),
  pi = PassengerImporter.new(DB_DIR+'RECORDS.csv')]
end

def main
  ci, si, pi = importers

  stops = si.stops.select{|s| s.car_class.starts_with?('R160')}

  #car_vis = CarVisualizer.new(ci.cars['R160b'], [[]])
  car_vis = CarVisualizer.new(ci.cars['R32'], [[]])

  [car_vis, ci, si, pi]
end

# The probability that a certain type of seat (seat by door, middle seat, standing by stanchion)
# will be occupied at any given time
# TODO this should be normalized by load factor
def stats_by_type
  ci, si, pi = importers

  stats = pi.passengers.each_with_object(Hash.new{0}) do |pass, stats|
    stop = si.stops.find{|s| s.id == pass.form_id}
    car = ci.cars[stop.car_class]
    type = space_type(pass.space, car)

    stats[type] += 1
  end

  totals = si.stops.each_with_object(Hash.new{0}) do |stop, totals|
    car = ci.cars[stop.car_class]
    car.spaces.each do |space|
      #puts "space: "+space.inspect
      type = space_type(space.ergo.space, car)
      totals[type] += 1
    end
  end
  
  p totals

  rates = Hash[*stats.map{|k, v| [k, v.to_f / totals[k]]}.flatten]
  rates
end

# make all the values sum to 1
def normalize(hash)
  
end
