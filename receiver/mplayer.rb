# Displays a link using mplayer.
class Receiver::MPlayer < Receiver::Base

  def initialize(opts = {})
    super("MPlayer")
    @options = opts[:options]
  end

  # Performs a version request to test if aria is online.
  def online?
    `which mplayer`
    return $?.success?
  end

  # Displays the given link using mplayer.
  def add(link, file_name = nil, cookies = nil)
    command = "mplayer #{@options} '#{link}'"
    $log.debug("exec `#{command}'")
    fork do
      exec command
    end
  end

end

