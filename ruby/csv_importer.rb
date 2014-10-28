require 'csv'

module CsvImporter
  attr_accessor :csv
  def initialize(filename)
    @filename = filename
    @csv = CSV.open(filename, 'r', headers: false, converters: :all)
  end
end

