require 'rake'
require 'rake/extensiontask'
require 'rake/testtask'

desc "Compile the Ragel state machines"
task :ragel do
  Dir.chdir 'ext/spyglass_parser' do
    target = "parser.c"
    File.unlink target if File.exist? target
    sh "ragel parser.rl -G2 -o #{target}"
    raise "Failed to compile Ragel state machine" unless File.exist? target
  end
end

Rake::ExtensionTask.new('spyglass_parser')

Rake::TestTask.new(:test => :compile) do |t|
  t.libs << 'test'
  t.ruby_opts << '-rubygems'
  t.test_files = FileList['test/*_test.rb']
end

require 'rocco/tasks'
Rocco.make 'doc/'

desc 'Build documentation'
task :doc => :rocco
directory 'doc/'

desc 'Build documentation and open in your browser for reading'
task :read => :doc do
  exec 'open doc/lib/spyglass.html'
end

desc 'Show the README'
task :readme do
  exec 'less README.md'
end

task :default => :readme

