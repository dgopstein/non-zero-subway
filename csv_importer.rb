require 'csv'

module CsvImporter
  attr_accessor :csv
  def initialize(filename)
    @filename = filename
    @csv = CSV.open(filename, 'r', headers: false, converters: :all)
  end

  def parse_csv(csv)
    1 / 0
  end
end

