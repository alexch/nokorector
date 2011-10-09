here = File.dirname __FILE__
proj = "#{here}/.."
lib = "#{proj}/lib"
require "#{lib}/nokorector"

require "wrong/adapters/rspec"

puts "Ruby #{RUBY_VERSION}"
