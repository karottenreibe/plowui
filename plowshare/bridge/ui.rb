require_relative 'base.rb'
require_relative '../cookie_jar.rb'

# The bridge on the UI side.
class Plowshare::Bridge::UI < Plowshare::Bridge::Base

  # Calls the given block when a captcha needs to be
  # solved.
  def initialize(dir, my_lock, other_lock, &captcha_solver)
    super(dir, my_lock, other_lock)
    @captcha_solver = captcha_solver
    @cookie_jar = CookieJar.new
    self.lock()
  end

  # Starts communicating with the child process.
  # Blocks until done.
  #
  # When finished, returns {
  #   :cookies => the cookies to send as an array of
  #       "name=value" strings
  #   :url => the URL to retrieve
  #   :name => the name of the file
  # }
  def start
    loop do
      message = self.receive
      method = message.first

      case method
      when "captcha"
        image_file = message[1]
        answer = @captcha_solver.call(image_file)
        self.send(answer)
      when "download"
        cookies = @cookie_jar.parse(message[1])
        # Send sync message so the download bridge
        # knows we read the cookie file
        # Then wait for it to acknowledge so the
        # temp directory does not get deleted before
        # the other end has read the message.
        self.send()
        self.receive()
        return {
          :cookies => cookies,
          :url => message[2],
          :name => message[3]
        }
      end
    end
  end

end

