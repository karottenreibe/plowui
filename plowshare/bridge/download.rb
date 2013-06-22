#!/usr/bin/ruby

require_relative 'base.rb'

# Sends download URL.
class Plowshare::Bridge::Download< Plowshare::Bridge::Base

  def run(module_name, original_url, cookie_path, download_url, file_name)
    self.send("download", cookie_path, download_url, file_name)
    # wait for one more message so we can be sure the other end has read
    # the cookie file
    self.receive()
    # Tell the other end we are done
    self.send_shutdown()
    exit 0
  end

end

Plowshare::Bridge::Download.external()
