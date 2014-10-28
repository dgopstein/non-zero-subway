Passenger = Struct.new(:id, :form_id, :gender, :space, :large_psgr, :legs_on_seat, :bag)

class PassengerImporter
  include CsvImporter

  attr_accessor :passengers

  def initialize(filename)
    super(filename)
    @passengers = parse_csv(@csv)
  end

  def parse_csv(csv)
    csv.drop(1).each_with_object([]) do |row, passengers|
      passengers << Passenger.new(*row.to_a)
    end
  end

  def by_form_id(id)
    passengers.select{|p| p.form_id == id}
  end
end
