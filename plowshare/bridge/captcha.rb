#!/usr/bin/ruby

require_relative 'base.rb'

# Sends a captcha file name.
class Plowshare::Bridge::Captcha < Plowshare::Bridge::Base

  def run(module_name, image_path, captcha_type)
    self.send("captcha", image_path)

    solved_text = self.receive

    # TODO
    exit 2 if solved_text == ".stop"
    exit 7 if solved_text == ".retry"

    puts solved_text

    # Tell the other end we are done
    self.shutdown()
    exit 0
  end

end

Plowshare::Bridge::Captcha.external

