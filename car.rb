require 'csv'

require 'csv_importer.rb'
require 'passenger.rb'

def space_distance(s1, s2)
  c1, r1 = parse_space(s1)
  c2, r2 = parse_space(s2)

  [(c2 - c1).abs, (r2 - r1).abs]
end

def longitudinal_distance(s1, s2)
  space_distance(s1, s2).first
end

def manhattan_distance(s1, s2)
  space_distance(s1, s2).sum
end


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

  def doors
    plan.flatten.select{|space| !space.ergo.seat? && space.ergo.door.ergo.nonzero? }
  end

  def bottom_row
    ('a'..'z').to_a[height - 1]
  end

  def top_doors
    doors.select{|d| d.space[-1] == 'a'}
  end

  def bottom_doors
    doors.select{|d| d.space[-1] == bottom_row}
  end

  def top?(s)
    row = 
      if s.is_a?(String)
        parse_space(s).last
      else
        s
      end
    
    row.to_f / height < 1.0/2
  end

  def nearest_top_door(s)
    top_doors.min_by{|d| manhattan_distance(s.space, d.space)}
  end

  def nearest_door(s)
    ds = top?(s.space) ? bottom_doors : top_doors
    ds.min_by{|d| manhattan_distance(s.space, d.space)}
  end

  def to_s
    @name
  end
end

Space = Struct.new(:car_class, :space, :position, :pole, :wall, :door, :map, :legroom, :perpendicular, :seatpole, :vestibule) do
  def col_row
    parse_space(space)
  end

  def seat?
    position > 0
  end

  # Seat faces forwards or back (not sideways) and is against the wall
  def trans_edge?
    [1, 4].include?(perpendicular)
  end
  alias_method :nook?, :trans_edge?
end

def space_type(space_name, car)
  space = 
    if space_name.nil?
      nil or return :nil
    elsif space_name.is_a? String
      car.lookup_tbl[space_name] or return :unknown
    else
      space_name # They actually passed the full space struct
    end

  if space.position > 0
    if space.door > 0 then :seat_door
    elsif space.nook? then :seat_nook
    elsif space.seatpole > 0 then :seatpole
    elsif space.wall > 0 then :seat_wall
    else :seat_middle
    end
  else
    if space.door > 0 then :floor_door
    elsif space.pole > 0 then :floor_pole # pole NOT seatpole
    elsif space.wall > 0 then :floor_wall
    else :floor
    end
  end
end

def parse_space(space)
  str = if space.respond_to?(:space) then space.space else space end

  space_col, space_row = str.match(/([0-9.]+)(\w+)/).captures
  [space_col.to_i, (space_row.downcase.ord - 'a'.ord)]
end

class CarImporter
  include CsvImporter

  attr_accessor :cars

  def initialize(filename)
    super(filename)
    @cars = parse_csv(@csv)
    @cars['R68_section'] = sectionalize(@cars['R68'])
  end

  def sectionalize(car)
    Car.new(car.name+'_section').tap do |new_car|
      new_car.plan = car.plan.take_while{|r| r.first rescue true }
    end
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

