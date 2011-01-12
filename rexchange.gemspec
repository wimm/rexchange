version = File.read(File.expand_path("../VERSION", __FILE__)).strip

Gem::Specification.new do |s|
  s.name    = 'rexchange'
  s.version = version
  s.summary = "A pure ruby wrapper for the Microsoft Exchange Server WebDAV API."
  s.description = 'Library that implements the WebDAV API to interact with Exchange Servers.'
  s.required_ruby_version = '>= 1.8.7'

  s.authors = ["Sam Smoot", "Scott Bauer", "Daniel Kwiecinski"]
  s.email  = ["ssmoot@gmail.com", "bauer.mail@gmail.com", "daniel@lambder.com"]
  s.homepage = 'http://substantiality.net'
  s.rubyforge_project = 'rexchange'

  s.files = Dir['README', 'CHANGELOG', 'MIT-LICENSE', 'lib/**/*']
  s.extra_rdoc_files = ["README", "CHANGELOG", "MIT-LICENSE"]
  s.test_files = Dir['test/*.rb']
end
