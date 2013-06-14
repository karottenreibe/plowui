require './base.rb'

# Sends a captcha file name.
class CaptchaBridge < BridgeBase

  def initialize(fifo_in, fifo_out, image_path)
    super("captcha", fifo_in, fifo_out)
    self.send(image_path)
    solved_text = self.receive

    exit 2 if solved_text == ".stop"
    exit 7 if solved_text == ".retry"
    puts solved_text
    exit 0
  end

end

fifo_in = ARGV[1]
fifo_out = ARGV[2]
image_path = ARGV[4]
CaptchaBridge.new(fifo_in, fifo_out, image_path)

