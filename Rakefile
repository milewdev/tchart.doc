require "rake/testtask"


task :default => [ :generate_chart_images ]


desc "Generate chart images"
task :generate_chart_images do
  generate_charts("index.html")
end


# Could refactor but it's just a script.
def generate_charts(filename)
  contents = File.open(filename) { |f| f.read }
  contents.scan( /<!-- @tchart (.*?) -->(.*?)<!-- @end -->/m ) do |fn, spec|
    puts fn
    Dir.chdir("images/src") do
      File.open("drawing.txt", "w") { |f| f.write(spec) }
      system "tchart drawing.txt drawing.tikz"
      system "pdftex -interaction=batchmode drawing.tex > /dev/null"
      system "pdfcrop --margins '30 5 30 10' drawing.pdf cropped.pdf > /dev/null"
      system "gs -q -dQUIET -dSAFER -dBATCH -dNOPAUSE -dNOPROMPT -dMaxBitmap=500000000 -dAlignToPixels=0 -dGridFitTT=2 -dTextAlphaBits=4 -dGraphicsAlphaBits=4 -r100 -sDEVICE=jpeg -dJPEGQ=100 -sOutputFile=../#{fn} cropped.pdf"
      system "rm drawing.txt drawing.tikz drawing.pdf cropped.pdf drawing.log drawing.pgf"
    end
  end
end
