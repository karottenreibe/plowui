require_relative 'bridge/ui.rb'
require_relative '../async.rb'

# Handles asynchronous communication with plowdown.
# Allows for solving captchas.
class Plowshare::Download < Async::Task

  # Returns true if a captcha needs to be solved.
  def needs_captcha?
    return @status == :captcha
  end

  # Calls plowshare to perform the download.
  def run(link)
    fifo_in = Tempfile.new
    fifo_out = Tempfile.new

    bridge = Plowshare::Bridge::UI.new(fifo_in, fifo_out) do |captcha_url|
      self.change_status(:captcha, captcha_url)
      sleep(1) while needs_captcha?
      @result
    end

    download_bridge = bridge("download")
    captcha_bridge = bridge("captcha")

    async_call("plowdown --skip-final --run-after '#{download_bridge}' --captchaprogram '#{captcha_bridge}' #{link}")
    @result = bridge.start
  ensure
    [fifo_in, fifo_out].each do |fifo|
      if fifo
        fifo.close
        fifo.unlink
      end
    end
  end

  # Returns the absolute path to the bridge with the given name.
  def bridge(name)
    return File.expand_path(File.join(File.dirname(__FILE__), "bridge", "#{name}.rb"))
  end

  # Must be called when the user solved the captcha
  # to continue the download.
  def solved_captcha(captcha_text)
    self.change_status(:running, captcha_text)
  end

end

