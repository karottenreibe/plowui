#!/usr/bin/ruby

require_relative 'base.rb'

# Sends a captcha file name.
class Plowshare::Bridge::Captcha < Plowshare::Bridge::Base

  def initialize(fifo_in, fifo_out, image_path)
    super(fifo_in, fifo_out)
    self.send("captcha")

    self.wait_for_sync
    self.send(image_path)

    solved_text = self.receive

    exit 2 if solved_text == ".stop"
    exit 7 if solved_text == ".retry"

    puts solved_text
    exit 0
  end

end

fifo_in = ARGV[0]
fifo_out = ARGV[1]
image_path = ARGV[3]
Plowshare::Bridge::Captcha.new(fifo_in, fifo_out, image_path)

