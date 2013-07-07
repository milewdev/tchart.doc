require 'date'

module Resume
  module DataReader
    def self.read(filename) # => settings, chart_items
      File.open(filename) do |f| 
        settings, chart_items, errors = DataParser.parse(filename, f) 
        print_errors_and_fail(errors) if not errors.empty?
        [ settings, chart_items ]
      end
    end
    
    def self.print_errors_and_fail(errors)
      errors.each { |error| $stderr.puts(error) }
      raise ApplicationError, "Errors found; aborting."
    end
  end
end
