# Run Rake in this JRuby process; Bundler exec would require an external jruby binary.
require 'bundler/setup'
require 'rake'
Rake.application.run(['demo:prepare'])
