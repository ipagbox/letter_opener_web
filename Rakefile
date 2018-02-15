#!/usr/bin/env rake
# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'appraisal'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

task :default => [:clean, :all]

task :all do |t|
  if ENV['BUNDLE_GEMFILE']
    exec('rake spec')
  else
    exec("rm -f gemfiles/*.lock")
    Rake::Task["appraisal:gemfiles"].execute
    Rake::Task["appraisal:install"].execute
    exec('rake appraisal')
  end
end

RSpec::Core::RakeTask.new(:spec)

task :clean do |t|
  FileUtils.rm_rf 'Gemfile.lock'
  FileUtils.rm_rf 'gemfiles/*.lock'
end
