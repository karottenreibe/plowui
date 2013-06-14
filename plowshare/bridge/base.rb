# Facilitates communication with PlowUI via a named pipe.
class BridgeBase

  def initialize(topic, fifo_in, fifo_out)
    @fifo_in = fifo_in
    @fifo_out = fifo_out
    raise ArgumentError.new("no FIFO path given") unless @fifo
    self.send(topic) if topic
  end

  # Sends a line of text through the FIFO.
  def send(line)
    File.open(@fifo_out, "w+") do |file|
      file.puts(line)
    end
  end

  # Receives a line of text from the FIFO.
  def receive
    File.open(@fifo_in, "r+") do |file|
      return file.gets.strip
    end
  end

end

