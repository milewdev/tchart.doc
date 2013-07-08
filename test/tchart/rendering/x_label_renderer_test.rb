require_relative '../../test_helper'

module TChart
  describe XLabelRenderer, "render" do
    it "generates TeX code to render an x-axis label" do
      x_label = stub( date: Date.new(1985,1,1), x_coordinate: 20, y_coordinate: -3, y_length: 100 )
      XLabelRenderer.new.render(x_label).must_equal <<-EOS.unindent.indent(4)
        % 1985
        \\draw (20.00mm, -3.00mm) node [xlabel] {1985};
        \\draw [draw = black!5] (20.00mm, 0.00mm) -- (20.00mm, 100.00mm);
      EOS
    end
  end
end
