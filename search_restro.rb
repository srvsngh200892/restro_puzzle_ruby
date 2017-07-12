require 'pry'
require './restro_puzzle_script'

restro_script = RestroPuzzleScript.new(ARGV)
restro_script.search_restaurants
restro_script.display_result
