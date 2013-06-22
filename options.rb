require 'xdg'
require 'yaml'

# Parses config options from the config file.
class Options

  # Whether to show debug messages on the console.
  attr_reader :debug

  # An options hash for aria.
  # See Aria#initialize for more info on that.
  attr_reader :aria

  def initialize
    opts = {
      :debug => false,
      :aria => {},
    }

    config_file = File.join(XDG['CONFIG_HOME'].to_s, "plowui.yml")
    if File.exist?(config_file)
      user_opts = YAML.load_file(config_file)
      opts.merge!(user_opts)
    end

    @debug = opts[:debug]
    @aria = opts[:aria]
  end

end

