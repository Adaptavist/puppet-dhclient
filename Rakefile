require 'rubygems'
require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-lint'
require 'puppet-syntax/tasks/puppet-syntax'

PuppetLint.configuration.send('disable_quoted_booleans')
PuppetLint.configuration.send('disable_case_without_default')
ENV['STRICT_VARIABLES']='no'
task :default => [:spec, :lint, :syntax]


