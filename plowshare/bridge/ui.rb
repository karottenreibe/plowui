require_relative 'base.rb'

# The bridge on the UI side.
class Plowshare::Bridge::UI < Plowshare::Bridge::Base

  # Calls the given block when a captcha needs to be
  # solved.
  def initialize(fifo_in, fifo_out)
    super(fifo_in, fifo_out)
  end

  # Starts communicating with the child process.
  # When finished, returns {
  #   :cookies => the cookies to send as name=value pairs separated
  #       by new lines
  #   :url => the URL to retrieve
  #   :name => the name of the file
  # }
  def start
    loop do
      method = self.receive.first
      self.send_sync

      case method
      when "captcha"
        image_file = self.receive.first
        answer = yield(image_file)
        self.send(answer)
      when "download"
        args = self.receive(3)
        return {
          :cookies => args[0],
          :url => args[1],
          :name => args[2]
        }
      end
    end
  end

end

