require './lib/resume/version'

Gem::Specification.new do |s|
  s.name                  = "tchart-ruby"
  s.summary               = "Generate TeX/TikZ charts"
  s.description           = File.read(File.join(File.dirname(__FILE__), 'README'))
  s.license               = 'MIT'
  s.requirements          = [ 'none' ]
  s.version               = "#{Resume::Version}"
  s.author                = "Michael Lewandowski"
  s.email                 = "milewgit@gmail.com"
  #s.homepage              = "http://ml.somewhere.com"
  s.platform              = Gem::Platform::RUBY
  s.required_ruby_version = '>=1.9'
  s.files                 = Dir[ '**/**' ]
  s.executables           = [ 'tchart-ruby' ]
  s.test_files            = Dir[ "test/*_test.rb"]
  s.has_rdoc              = false
end