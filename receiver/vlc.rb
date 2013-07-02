require 'tempfile'

# Displays a link using vlc.
class Receiver::VLC < Receiver::Base

  def initialize(opts = {})
    super("VLC")
    @options = opts[:options]
  end

  # Checks if vlc and wget are available
  def online?
    `which vlc && which wget`
    return $?.success?
  end

  # Displays the given link using vlc.
  def add(link, file_name = nil, cookies = nil)
    fork do
      Tempfile.open('plowui-mplayer-cookies') do |file|
        file.puts(cookies)

        command = "wget --load-cookies '#{file.path}' | vlc #{@options} '#{link}'"
        $log.debug("exec `#{command}'")
        exec command
      end
    end
  end

end


