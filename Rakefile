# frozen_string_literal: true

require 'rake'

def ruby_files
  FileList['skills/*/scripts/*.rb', 'scripts/*.rb'].to_a.join(' ')
end

desc 'Run RuboCop'
task :rubocop do
  sh 'bundle exec rubocop', verbose: false do |ok, _res|
    puts ok ? 'RuboCop: PASS' : 'RuboCop: FAIL (see above for details)'
  end
end

desc 'Run Flay (duplicate code detection)'
task :flay do
  sh "bundle exec flay #{ruby_files}", verbose: false do |ok, _res|
    puts ok ? 'Flay: PASS' : 'Flay: FAIL (see above for details)'
  end
end

desc 'Run Flog (complexity analysis)'
task :flog do
  sh "bundle exec flog -a #{ruby_files}", verbose: false do |ok, _res|
    puts ok ? 'Flog: PASS' : 'Flog: FAIL (see above for details)'
  end
end

desc 'Run Reek (code smell detection)'
task :reek do
  sh "bundle exec reek #{ruby_files}", verbose: false do |ok, _res|
    puts ok ? 'Reek: PASS' : 'Reek: FAIL (see above for details)'
  end
end

desc 'Run all code quality checks'
task :quality do
  results = {}

  puts '=' * 60
  puts 'Running RuboCop...'
  puts '=' * 60
  results[:rubocop] = system('bundle exec rubocop')

  puts
  puts '=' * 60
  puts 'Running Flay...'
  puts '=' * 60
  results[:flay] = system("bundle exec flay #{ruby_files}")

  puts
  puts '=' * 60
  puts 'Running Flog...'
  puts '=' * 60
  results[:flog] = system("bundle exec flog -a #{ruby_files}")

  puts
  puts '=' * 60
  puts 'Running Reek...'
  puts '=' * 60
  results[:reek] = system("bundle exec reek #{ruby_files}")

  puts
  puts '=' * 60
  puts 'SUMMARY'
  puts '=' * 60
  results.each do |tool, passed|
    status = passed ? "\e[32mPASS\e[0m" : "\e[31mFAIL\e[0m"
    puts "  #{tool}: #{status}"
  end
  puts '=' * 60

  exit 1 unless results.values.all?
end

desc 'Run Cucumber features'
task :cucumber do
  sh 'bundle exec cucumber', verbose: false do |ok, _res|
    puts ok ? 'Cucumber: PASS' : 'Cucumber: FAIL (see above for details)'
  end
end

desc 'Run all tests'
task :test do
  Rake::Task['cucumber'].invoke
end

task default: :quality
