#!/usr/bin/ruby

require_relative 'base.rb'

# Sends a captcha file name.
class Plowshare::Bridge::Captcha < Plowshare::Bridge::Base

  def initialize(dir, my_lock, other_lock, debug, image_path)
    super(dir, my_lock, other_lock, debug)
    self.send("captcha", image_path)

    solved_text = self.receive

    exit 2 if solved_text == ".stop"
    exit 7 if solved_text == ".retry"

    puts solved_text

    # Tell the other end we are done
    self.send_shutdown()
    exit 0
  end

end

dir = ARGV[0]
my_lock = ARGV[1]
other_lock = ARGV[2]
debug = ARGV[3] == "true"

image_path = ARGV[5]
Plowshare::Bridge::Captcha.new(dir, my_lock, other_lock, debug, image_path)

