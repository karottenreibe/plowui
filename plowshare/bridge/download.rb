require './base.rb'

# Sends download URL.
class DownloadBridge < BridgeBase

  def initialize(fifo_in, fifo_out, cookie_path, download_url, file_name)
    super("download", fifo_in, fifo_out)
    self.send(cookie_path)
    self.send(download_url)
    self.send(file_name)
    exit 0
  end

end

fifo_in = ARGV[1]
fifo_out = ARGV[2]
cookie_path = ARGV[5]
download_url = ARGV[6]
file_name = ARGV[7]
DownloadBridge.new(fifo_in, fifo_out, cookie_path, download_url, file_name)


