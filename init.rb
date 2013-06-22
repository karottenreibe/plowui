# Performs initialization tasks
# This file is also required by the bridge scripts
# in order to have the same basic setup.

require_relative 'options.rb'
$options = Options.new

require 'logger'
$log = Logger.new(STDOUT)
$log.level = Logger::WARN
$log.level = Logger::DEBUG if $options.debug
$log.formatter = proc do |severity, time, program_name, message|
  "#{severity}\t#{message}\n"
end

Thread::abort_on_exception = true

$re_trapped = false
trap ('SIGINT') {
  exit! if $re_trapped
  $re_trapped = true
  $stderr.puts "asking GTK to exit. Press Ctrl-C again to force exit"
  Gtk.main_quit
}

