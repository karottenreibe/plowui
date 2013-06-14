module Plowshare
  module Bridge
  end
end

# Facilitates communication with PlowUI via a named pipe.
class Plowshare::Bridge::Base

  def initialize(fifo_in, fifo_out)
    @fifo_in = fifo_in
    @fifo_out = fifo_out
    raise ArgumentError.new("no input FIFO path given") unless @fifo_in
    raise ArgumentError.new("no output FIFO path given") unless @fifo_out
  end

  # Returns true if both FIFO files have been created.
  def ready?
    return (File.exist?(@fifo_out) and File.exist?(@fifo_in))
  end

  # Waits until it received any message at all.
  def wait_for_sync
    self.receive
  end

  # Sends a synchronization message.
  def send_sync
    self.send("")
  end

  # Sends several lines of text through the FIFO.
  # Will block until the FIFOs have been created.
  def send(*messages)
    until self.ready? do
      sleep(0.1)
    end

    File.open(@fifo_out, "w+") do |file|
      messages.each do |message|
        file.puts(message)
      end
    end
  end

  # Receives n lines of text from the FIFO.
  def receive(n = 1)
    answer = []
    File.open(@fifo_in, "r+") do |file|
      n.times do
        answer << file.gets.strip
      end
    end
    return answer
  end

end

