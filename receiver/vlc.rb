require 'tempfile'

# Displays a link using vlc.
class Receiver::VLC < Receiver::Base

  def initialize(opts = {})
    super("VLC")
    @options = opts[:options]
  end

  # Performs a version request to test if aria is online.
  def online?
    `which vlc`
    return $?.success?
  end

  # Displays the given link using vlc.
  def add(link, file_name = nil, cookies = nil)
    fork do
      command = "vlc #{@options} '#{link}'"
      $log.debug("exec `#{command}'")
      exec command
    end
  end

end


