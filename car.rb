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

  def doors
    plan.flatten.select{|space| space.ergo.door.ergo.nonzero? }
  end

  def to_s
    @name
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

