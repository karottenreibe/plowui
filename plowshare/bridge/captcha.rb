#!/usr/bin/ruby

require_relative 'base.rb'

# Sends a captcha file name.
class Plowshare::Bridge::Captcha < Plowshare::Bridge::Base

  def initialize(dir, my_lock, other_lock, image_path)
    super(dir, my_lock, other_lock)
    self.send("captcha", image_path)

    solved_text = self.receive

    exit 2 if solved_text == ".stop"
    exit 7 if solved_text == ".retry"

    puts solved_text
    exit 0
  end

end

dir = ARGV[0]
my_lock = ARGV[1]
other_lock = ARGV[2]
image_path = ARGV[4]
Plowshare::Bridge::Captcha.new(dir, my_lock, other_lock, image_path)

