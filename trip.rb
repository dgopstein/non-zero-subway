require 'csv_importer.rb'
require 'facets'
require 'lib/deep_enumerable/lib/deep_enumerable.rb'

Stop = Struct.new(:id, :date, :from, :to, :lv_time, :arr_time, :car_class, :line, :form_dir, :occupancy)

class StopImporter
  include CsvImporter

  attr_accessor :stops

  def initialize(filename)
    super(filename)
    @stops = parse_csv(@csv)
  end

  def parse_csv(csv)
    csv.drop(1).each_with_object([]) do |row, stops|
      stops << Stop.new(*row.to_a).tap do |s|
        s.date = Date.strptime(s.date, '%m/%d/%Y 00:00:00')
        s.lv_time &&= DateTime.strptime(s.lv_time, '%m/%d/%Y %H:%M:%S')
        s.arr_time &&= DateTime.strptime(s.arr_time, '%m/%d/%Y %H:%M:%S')
      end
    end
  end

  # glob together all stops that happened consecutively
  def self.link_stops(stops)
    stops.select(&:lv_time) # some forms don't have leave-times, remove them
         .group_by(&:line)
         .map_values do |stops|
           sorted_stops = stops.sort_by{|stop| stop.lv_time} # put all the stops in order by time
           chain_consecutive(sorted_stops){|a, b| a.to == b.from} # glob together all stops that happened consecutively
         end
  end

  def by_id
    @by_id ||= stops.mash{|s| [s.id, s]}
  end

  def trips
    StopImporter.link_stops(stops)
        .map_values{|chains| chains.select{|s| s.length > 1}} # remove rides of only one stop
        .reject{|k,v| v.empty?} # remove lines with no long rides
  end
end

# TODO util this
#
# >> chain_consecutive([-1, 1, 2, 3, 5, 6, 8]) {|a, b| a+1 == b }
# => [[-1], [1, 2, 3], [5, 6], [8]]
#
def chain_consecutive(arr, &block)
  arr.each_with_object([[]]) do |a, sum|
    last = sum.last.last
    if last.nil? || block.call(last, a)
        sum.last << a
    else
        sum << [a]
    end
  end
end

