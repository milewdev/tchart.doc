require_relative '../../test_helper'

module TChart
  describe DataParser do
    it "reads all lines from the data source" do
      data = StringIO.new("1\n2\n3\n")
      DataParser.parse('filename.txt', data)
    end
    it "ignores blank lines" do
      data = StringIO.new("1\n \n3\n")
      _, items, _ = DataParser.parse('filename.txt', data)
      items.map { |chart_item| chart_item.name }.must_equal(['1', '3'])
    end
    it "ignores empty lines" do
      data = StringIO.new("1\n\n3\n")
      _, items, _ = DataParser.parse('filename.txt', data)
      items.map { |chart_item| chart_item.name }.must_equal(['1', '3'])
    end
    it "ignores comment lines" do
      data = StringIO.new("1\n# comment\n3\n")
      _, items, _ = DataParser.parse('filename.txt', data)
      items.map { |chart_item| chart_item.name }.must_equal(['1', '3'])
    end
    it "ignores trailing comments" do
      data = StringIO.new("1\n2 # comment\n3\n")
      _, items, _ = DataParser.parse('filename.txt', data)
      items.map { |chart_item| chart_item.name }.must_equal(['1', '2', '3'])
    end
    it "does not treat escaped hashes (#) as comments" do
      data = StringIO.new("C\\#\n")
      _, items, _ = DataParser.parse('filename.txt', data)
      items[0].name.must_equal 'C#'
    end
    it "include the data source name and line number in error messages" do
      data = StringIO.new("unknown_setting_name = 42\n")
      _, _, errors = DataParser.parse('filename.txt', data)
      errors.find {|item| item =~ /^filename.txt, 1:/}.wont_be_nil
    end
  end
  
  describe DataParser, "settings" do
    it "parses settings with no sign" do
      data = StringIO.new("chart_width=42\n")
      settings, _, _ = DataParser.parse('filename.txt', data)
      settings.chart_width.must_equal 42
    end
    it "parses settings with a plus sign" do
      data = StringIO.new("chart_width=+42\n")
      settings, _, _ = DataParser.parse('filename.txt', data)
      settings.chart_width.must_equal 42
    end
    it "parses settings with a minus sign" do
      data = StringIO.new("chart_width=-42\n")
      settings, _, _ = DataParser.parse('filename.txt', data)
      settings.chart_width.must_equal (-42)
    end
    it "parses settings with a decimal but no decimal places" do
      data = StringIO.new("chart_width=42.\n")
      settings, _, _ = DataParser.parse('filename.txt', data)
      settings.chart_width.must_equal 42
    end
    it "parses settings with decimal places" do
      data = StringIO.new("chart_width=42.24\n")
      settings, _, _ = DataParser.parse('filename.txt', data)
      settings.chart_width.must_equal 42.24
    end
    it "parses settings with trailing zeros after the decimal place" do
      data = StringIO.new("chart_width=42.240\n")
      settings, _, _ = DataParser.parse('filename.txt', data)
      settings.chart_width.must_equal 42.24
    end
    it "parses settings with leading zeros" do
      data = StringIO.new("chart_width=0042\n")
      settings, _, _ = DataParser.parse('filename.txt', data)
      settings.chart_width.must_equal 42
    end
    it "returns an error if the settings value is not a number for numeric settings" do
      data = StringIO.new("chart_width=42mm\n")
      _, _, errors = DataParser.parse('filename.txt', data)
      errors.must_include "filename.txt, 1: \"42mm\" is not a number; expecting e.g. 123 or 123.45"
    end
    it "parses numbers for numeric settings" do
      settings = Settings.new
      settings.setting_names.select {|setting_name| settings.send(setting_name).kind_of? Integer }.each do |setting_name|
        data = StringIO.new("#{setting_name}=42\nitem")
        _, _, errors = DataParser.parse('filename.txt', data)
        errors.empty?.must_equal true, errors
      end
    end
    it "returns an error is the setting value for a numeric setting is not a number" do
      settings = Settings.new
      settings.setting_names.select {|setting_name| settings.send(setting_name).kind_of? Integer }.each do |setting_name|
        data = StringIO.new("#{setting_name}=abc\nitem")
        _, _, errors = DataParser.parse('filename.txt', data)
        errors.must_include "filename.txt, 1: \"abc\" is not a number; expecting e.g. 123 or 123.45"
      end
    end
    it "parses strings for string settings" do
      settings = Settings.new
      settings.setting_names.select {|setting_name| settings.send(setting_name).kind_of? String }.each do |setting_name|
        data = StringIO.new("#{setting_name}=abc def ghi\nitem")
        _, _, errors = DataParser.parse('filename.txt', data)
        errors.empty?.must_equal true, errors
      end
    end
    it "returns an error if the setting name is unknown" do
      data = StringIO.new("unknown=42\n")
      _, _, errors = DataParser.parse('filename.txt', data)
      errors.find {|item| item =~ /^filename.txt, 1: unknown setting \"unknown\"; expecting one of:/}.wont_be_nil
    end
    it "ignores spaces around the equals sign in a setting" do
      data = StringIO.new("chart_width = 42\n")
      settings, _, _ = DataParser.parse('filename.txt', data)
      settings.chart_width.must_equal 42
    end
    it "ignores leading spaces before the setting name" do
      data = StringIO.new(" chart_width=42\n")
      settings, _, _ = DataParser.parse('filename.txt', data)
      settings.chart_width.must_equal 42
    end
    it "returns an error if the plot area is not wide enough" do
      data = StringIO.new("chart_width = 20 \n x_axis_label_width = 10 \n y_item_label_width = 10 \n")
      _, _, errors = DataParser.parse('filename.txt', data)
      errors.find {|item| item =~ /^filename.txt, 3: plot area is too narrow/}.wont_be_nil
    end
  end
  
  describe DataParser, "items" do
    it "parses chart items" do
      data = StringIO.new("Name | Style | 2000.4.14-2001.2.22\n")
      _, items, _ = DataParser.parse('filename.txt', data)
      items[0].name.must_equal 'Name'
      items[0].bar_style.must_equal 'Style'
      items[0].date_ranges.must_equal [ Date.new(2000,4,14)..Date.new(2001,2,22) ]
    end
    it "returns an error if the name is missing" do
      data = StringIO.new("|Style|2001\n")
      _, _, errors = DataParser.parse('filename.txt', data)
      errors.find {|item| item =~ /^filename.txt, 1: name is missing/}.wont_be_nil
    end
    it "returns an error if dates where supplied but the style is missing" do
      data = StringIO.new("Name||2001\n")
      _, _, errors = DataParser.parse('filename.txt', data)
      errors.find {|item| item =~ /^filename.txt, 1: style is missing/}.wont_be_nil
    end
    it "does not raise an error if no dates were supplied and the style is missing" do
      data = StringIO.new("Name||\n")
      _, _, errors = DataParser.parse('filename.txt', data)
      errors.length.must_equal 0
    end
    it "ignores escaped separator characters" do
      data = StringIO.new("Name1\\|\\|Name2|Style|2000\n")
      _, items, _ = DataParser.parse('filename.txt', data)
      items[0].name.must_equal 'Name1||Name2'
      items[0].bar_style.must_equal 'Style'
      items[0].date_ranges.must_equal [ Date.new(2000,1,1)..Date.new(2000,12,31) ]
    end
    it "returns a 'no chart items found' error if no chart items were found in the data and no other errors were found" do
      data = StringIO.new("# no chart items\n")
      _, _, errors = DataParser.parse('filename.txt', data)
      errors.must_equal [ "filename.txt, 1: no items found" ]
    end
    it "does not return a 'no chart items found' error if no chart items were found in the data but other errors were found" do
      data = StringIO.new("unknown_setting = 123\n")
      _, _, errors = DataParser.parse('filename.txt', data)
      errors.wont_include [ "filename.txt, 1: no chart items found" ]
    end
    it "allows separator lines" do
      data = StringIO.new("---\n")
      _, items, _ = DataParser.parse('filename.txt', data)
      items[0].must_be_instance_of Separator
    end
    it "allows chart items with no date ranges" do
      data = StringIO.new("Name | Style\n")
      _, items, _ = DataParser.parse('filename.txt', data)
      items[0].name.must_equal 'Name'
      items[0].bar_style.must_equal 'Style'
      items[0].date_ranges.must_equal []
    end
    it "allows chart items with no style and no date ranges" do
      data = StringIO.new("Name\n")
      _, items, _ = DataParser.parse('filename.txt', data)
      items[0].name.must_equal 'Name'
      items[0].bar_style.must_equal nil
      items[0].date_ranges.must_equal []
    end
    it "allows many date ranges" do
      data = StringIO.new("Name|Style|2000|2001|2002\n")
      _, items, _ = DataParser.parse('filename.txt', data)
      items[0].date_ranges.length.must_equal 3
    end
    it "strips leading and trailing spaces from the name" do
      data = StringIO.new(" \t Name \t |Style\n")
      _, items, _ = DataParser.parse('filename.txt', data)
      items[0].name.must_equal 'Name'
    end
    it "strips leading and trailing spaces from the style" do
      data = StringIO.new("Name| \t Style \t |2000\n")
      _, items, _ = DataParser.parse('filename.txt', data)
      items[0].bar_style.must_equal 'Style'
    end
    it "strips leading and trailing spaces from the dates" do
      data = StringIO.new("Name|Style| \t 2000 \t | \t 2001 \t \n")
      _, items, _ = DataParser.parse('filename.txt', data)
      items[0].date_ranges.must_equal [ Date.new(2000,1,1)..Date.new(2000,12,31), Date.new(2001,1,1)..Date.new(2001,12,31) ]
    end
    it "converts a range consisting of just a year to 1st January thru 31st December of that year" do
      data = StringIO.new("Name|Style|2000\n")
      _, items, _ = DataParser.parse('filename.txt', data)
      items[0].date_ranges.must_equal [ Date.new(2000,1,1)..Date.new(2000,12,31) ]
    end
    it "converts a range start consisting of just a year to 1st January of the year" do
      data = StringIO.new("Name|Style|2000-2001.2.22\n")
      _, items, _ = DataParser.parse('filename.txt', data)
      items[0].date_ranges.must_equal [ Date.new(2000,1,1)..Date.new(2001,2,22) ]
    end
    it "converts a range start consisting of a year and a month to the 1st of the month" do
      data = StringIO.new("Name|Style|2000.4-2001.2.22\n")
      _, items, _ = DataParser.parse('filename.txt', data)
      items[0].date_ranges.must_equal [ Date.new(2000,4,1)..Date.new(2001,2,22) ]
    end
    it "converts a range end consisting of just a year to 31st December of the year" do
      data = StringIO.new("Name|Style|2000.4.14-2001\n")
      _, items, _ = DataParser.parse('filename.txt', data)
      items[0].date_ranges.must_equal [ Date.new(2000,4,14)..Date.new(2001,12,31) ]
    end
    it "converts a range end consisting of a year and a month to the last day of the month" do
      data = StringIO.new("Name|Style|2000.4.14-2001.2\n")
      _, items, _ = DataParser.parse('filename.txt', data)
      items[0].date_ranges.must_equal [ Date.new(2000,4,14)..Date.new(2001,2,28) ]
    end
    it "allows whitespace around the dash (-) in a date range" do
      data = StringIO.new("Name|Style|2000.4.14 \t - \t 2001.2.22\n")
      _, items, _ = DataParser.parse('filename.txt', data)
      items[0].date_ranges.must_equal [ Date.new(2000,4,14)..Date.new(2001,2,22) ]
    end
    it "returns an error if a date cannot be parsed" do
      data = StringIO.new("Name|Style|2000.-2001\n")
      _, _, errors = DataParser.parse('filename.txt', data)
      errors.must_equal [ "filename.txt, 1: bad date range \"2000.-2001\"; expecting 2000.4.17-2001.7.21, or 2000.4-2001, etc." ]
    end
    it "returns an error if start date in a range is invalid" do
      data = StringIO.new("Name|Style|2000.4.34-2001.2.22\n")
      _, _, errors = DataParser.parse('filename.txt', data)
      errors.must_equal [ "filename.txt, 1: 2000.4.34: invalid date" ]
    end
    it "returns an error if end date in a range is invalid" do
      data = StringIO.new("Name|Style|2000.4.14-2001.2.32\n")
      _, _, errors = DataParser.parse('filename.txt', data)
      errors.must_equal [ "filename.txt, 1: 2001.2.32: invalid date" ]
    end
    it "allows ranges to be out of order" do
      data = StringIO.new("Name|Style|2001|2000\n")
      _, items, _ = DataParser.parse('filename.txt', data)
      items[0].date_ranges.must_equal [ Date.new(2001,1,1)..Date.new(2001,12,31), Date.new(2000,1,1)..Date.new(2000,12,31) ]
    end
    it "allows ranges to be back-to-back" do
      data = StringIO.new("Name|Style|2000|2001\n")
      _, items, _ = DataParser.parse('filename.txt', data)
      items[0].date_ranges.must_equal [ Date.new(2000,1,1)..Date.new(2000,12,31), Date.new(2001,1,1)..Date.new(2001,12,31) ]
    end
    it "returns an error if ranges overlap" do
      data = StringIO.new("Name|Style|2000-2001|2002-2004|2003-2005|2006-2007\n")
      _, _, errors = DataParser.parse('filename.txt', data)
      errors.must_equal [ "filename.txt, 1: date range 2002.1.1-2004.12.31 overlaps 2003.1.1-2005.12.31" ]
    end
    it "returns an error if a range end date is before a range start date" do
      data = StringIO.new("Name|Style|2001.2.22-2000.4.14\n")
      _, _, errors = DataParser.parse('filename.txt', data)
      errors.must_equal [ "filename.txt, 1: date range end 2000.4.14 before start 2001.2.22" ]
    end
    it "returns an error if two sets of dates are not separated by a pipe" do
      data = StringIO.new("Name|Style|2001-2002 2003-2004\n")
      _, _, errors = DataParser.parse('filename.txt', data)
      errors.must_equal [ "filename.txt, 1: bad date range \"2001-2002 2003-2004\"; expecting 2000.4.17-2001.7.21, or 2000.4-2001, etc." ]
    end
  end
end
