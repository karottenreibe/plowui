require 'tempfile'

# Displays a link using mplayer.
class Receiver::MPlayer < Receiver::Base

  def initialize(opts = {})
    super("MPlayer")
    @options = opts[:options]
  end

  # Checks if mplayer is available
  def online?
    `which mplayer`
    return $?.success?
  end

  # Displays the given link using mplayer.
  def handle(link, file_name = nil, cookies = nil)
    fork do
      Tempfile.open('plowui-mplayer-cookies') do |file|
        file.puts(cookies)

        command = "mplayer #{@options} -cookies -cookies-file '#{file.path}' '#{link}'"
        $log.debug("exec `#{command}'")
        exec command
      end
    end
  end

end

