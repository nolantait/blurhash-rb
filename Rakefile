# frozen_string_literal: true

require "yard"

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "rubocop/rake_task"

RuboCop::RakeTask.new

YARD::Rake::YardocTask.new do |t|
  t.files = ["lib/**/*.rb"]
  # t.options = ["--any", "--extra", "--opts"]
  t.stats_options = ["--list-undoc"]
end

task default: %i[spec rubocop]
