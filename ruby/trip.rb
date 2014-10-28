require 'csv_importer.rb'

Stop = Struct.new(:id, :date, :from, :to, :lv_time, :arr_time, :car_class, :line, :form_dir, :occupancy)

class FormImporter
  include CsvImporter

  attr_accessor :stops

  def initialize(filename)
    super(filename)
    @stops = parse_csv(@csv)
  end

  def parse_csv(csv)
    csv.drop(1).each_with_object([]) do |row, stops|
      stop = Stop.new(*row.to_a)
      stop.date = DateTime.parse(stop.date)
      stops << stop
    end
  end

  def self.link_stops(stops)
    
  end
end

