require_relative 'bridge/ui.rb'
require_relative '../async.rb'

require 'tmpdir'

# Handles asynchronous communication with plowdown.
# Allows for solving captchas.
class Plowshare::Download < Async::Task

  # Can be set to indicate the the captcha is currently being solved.
  attr_accessor :solving

  # The url that is being downloaded.
  attr_accessor :url

  # Returns true if a captcha needs to be solved.
  def needs_captcha?
    return @status == :captcha
  end

  # Calls plowshare to perform the download.
  def run(link)
    @name = "downloading #{link}"
    @url = link

    Dir.mktmpdir('plowui_bridge') do |tmp_dir|
      ui_bridge = Plowshare::Bridge::UI.new(tmp_dir, 'ui', 'other') do |captcha_url|
        @solving = false
        self.change_status(:captcha, captcha_url, "waiting for user input")
        sleep(1) while needs_captcha?
        @result
      end

      download_bridge = self.bridge("download", tmp_dir)
      captcha_bridge = self.bridge("captcha", tmp_dir)

      self.async_call("plowdown --skip-final --run-after '#{download_bridge}' --captchaprogram '#{captcha_bridge}' #{link}")
      @result = ui_bridge.start
      @status = :success
    end
  end

  # Executes the given command but does not wait for it to complete.
  def async_call(command)
    job = fork do
      exec command
    end
    Process.detach(job)
  end

  # Creates an executable shell file in the given directory that runs
  # the bridge with the given name.
  def bridge(name, dir)
    path = File.expand_path(File.join(File.dirname(__FILE__), "bridge", "#{name}.rb"))
    command = %Q{#!/bin/sh\n#{path} '#{dir}' other ui "$@"}
    runner = "#{dir}/#{name}-bridge.sh"
    File.open(runner, "w") do |file|
      file.puts(command)
      file.chmod(0700)
    end
    return runner
  end

  # Must be called when the user solved the captcha
  # to continue the download.
  def solved_captcha(captcha_text)
    self.change_status(:running, captcha_text)
  end

end

