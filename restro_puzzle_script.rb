require 'optparse'
require 'csv'
require 'pry'

class RestroPuzzleScript

  attr_reader :parameters

  def initialize(parameters)
    @parameters ||= parameters
    @restro, @restaurants, @dishes = {},[],[]
  end

  # ouput the result

  def display_result
    return p nil if @restaurants.empty?
    result = @restaurants.first
    puts "#{result[:restaurant_id]}, #{result[:price]}"
  end

  # check the parameters are valid
  # read the data from csv
  # return the array of resrto id and items (incase of multiple resro return restro with minimum item)
  # if aregument not valid print error message

  def search_restaurants
    if validate_parameters?
      read_resto_data_from_file
      build_dishes unless @restro.empty?
      @restaurants
    else
      puts "Invalid parameters! please provide argument like this ruby search_restro.rb sample.csv item1 item2"
    end
  end

  private

  def build_dishes
    @dishes = @parameters[1..@parameters.size-1]
    locate_restro_with_price
  end

  # Reads the input csv file and populates the @resturants attr_accessor.
  # and take data structure in the format of array of hahses
  #example
  #{1=>
  #[{:price=>2.0, :items=>["A"]},
  # {:price=>1.25, :items=>["B"]},
  # {:price=>2.0, :items=>["C"]},
   #{:price=>1.0, :items=>["D"]},
   #{:price=>1.0, :items=>["A", "B"]},
   #{:price=>1.5, :items=>["A", "C"]},
   #{:price=>2.5, :items=>["A", "D"]}]}

  def read_resto_data_from_file
    @csv_name = @parameters.first
    csv = ::CSV::parse(File.open(@csv_name, 'r') {|f| f.read })
    create_hash(csv)
  rescue => e
    @restro = []
  end

  def create_hash(csv)
    csv.each do |rec|
      rec.compact!  #Eliminate all nils caused by empty fields
      rec.map(&:strip!).compact! #Eliminate all leading/trailing white spaces and empty space chars in fields
      next if rec.length < 3 #Ignore if the particular row has not enough of information.

      rest_id = rec[0] && rec[0].to_i
      price = rec[1] && rec[1].to_f
      items = rec.slice(2..rec.length-1).flatten

      unless @restro.include? rest_id
        @restro[rest_id] = []
      end

      menu_entry = {price: price, items: items}
      @restro[rest_id].push menu_entry
    end
  end


  # this return the array of best priced restaurants for the given order.

  def locate_restro_with_price
    @restro.each do |restaurant, menu|
      @restaurants.concat optimal_price_restaurant(menu, restaurant)
    end
    @restaurants.sort! do |x,y|
      x[:price] <=> y[:price]
    end
  end

  #pass the menu ({:prices=>[prices1, prices2], :items=>["item1", ["item1", "item2", "item3"]] )
  # return the minimum price

  def optimal_price_restaurant(menu, restaurant)
    meal_combos = []
    @dishes.size.downto(1) do |i|
      menu.combination(i) do |combination|
        total_pice = build_rates(combination)
        total_pice[:restaurant_id] = restaurant
        meal_combos.push total_pice
      end
    end
    meal_combos.find_all do |meal|
      flag = true
      @dishes.each do |my_item|
        flag = flag && meal[:items].include?(my_item)
      end
      flag
    end
  end

  def build_rates(menu_entries)
    dishes = {price: 0.0, items: []}
    menu_entries.each do |entry|
      dishes[:price] += entry[:price]
      dishes[:items].concat(entry[:items])
    end
    dishes
  end

  def get_revalant_data(record)
    restro_id = record[0] && record[0].to_i
    price = record[1] && record[1].to_f
    items = record.slice(2..record.length-1).flatten
    return [restro_id, price, items]
  end

  def process_valid_data(record)
    record.compact!
    record.map(&:strip!).compact!
    return record.length < 3
  end

  #check the agrument length and parse option , if two return true else false

  def validate_parameters?
    opts = OptionParser.new
    opts.parse!(@parameters) rescue return false
    @parameters.length >= 2
  end
end
