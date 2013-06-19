require_relative 'bridge/ui.rb'

# Handles asynchronous communication with plowdown.
# Allows for solving captchas.
class Plowshare::DownloadAttempt

  # Returns the URL of a captcha image, if solving
  # a captcha is required.
  # Otherwise, contains nil.
  attr_reader :captcha

  # When the download attempt was successful, contains
  # the final download URL.
  attr_reader :download_url

  # Contains an array of cookie strings that can be passed
  # as headers to the downloader.
  # C.f. http://sourceforge.net/apps/phpbb/aria2/viewtopic.php?f=2&t=63
  attr_reader :cookies

  # If an error occurred, returns its description. Otherwise nil.
  attr_reader :error

  # Tries to download the given link.
  def initalize(link)
    @captcha = nil
    @download_url = nil
    @cookies = []
    @link = link
    fifo_in = Tempfile.new
    fifo_out = Tempfile.new
    # TODO .close .unlink
    @bridge = Plowshare::Bridge::UI.new(fifo_in, fifo_out)

    Thread.new do
      self.download
    end
  end

  # Returns true if a captcha needs to be solved.
  def needs_captcha?
    return @captcha != nil
  end

  # Returns true if the final download URL was retrieved.
  def done?
    return @download_url != nil
  end

  # Run in a thread. Calls plowshare to perform the download.
  def download(link)
    script_dir = "" #TODO

    output, status = call("plowdown --skip-final --printf '%f%n%d' #{link}")
    return nil, status unless output

    lines = output.split(/\n/)
    return lines[0], lines[1]
  end

  # Must be called when the user solved the captcha
  # to continue the download.
  def solved_captcha(captcha_text)
    @captcha = nil
    # TODO
  end

end

