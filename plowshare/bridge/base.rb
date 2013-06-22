require 'fileutils'

# Some classes that use this base class may be run as external
# scripts. Thus these modules may not have been created.
module Plowshare
  module Bridge
  end
end

# Facilitates synchronized message communication via files
# between two participants.
#
# The following conditions must hold at all times:
# * There is exactly one reader and one writer
# * After a message has been passed from A to B,
#   A becomes the reader and B the writer.
# * The first reader must be known to both parties.
#   He must lock his lock before the other party
#   can access the bridge.
# * The writer writes his messages,
#   then locks his lock,
#   then releases the other lock,
#   then becomes the reader.
# * The reader waits for his lock to be released,
#   then reads the message,
#   then becomes the writer.
# * Noone must ever lock the other's lock or unlock
#   their own lock.
# * Both partners must know when a shutdown will occur.
#   When it is time, one partner must send the shutdown
#   signal, while the other partner must perform a read.
#   When this read exits, it must delete the temporary
#   directory used for communication.
#
# Subclasses of an external bridge must implement #run
# in which they must perform their communication.
# Shutdown will behandled for them automatically.
# To start such a bridge, the bridge classe's #external
# method has to be called.
class Plowshare::Bridge::Base

  # Starts the bridge as an external bridge.
  def self.external
    require_relative '../../init.rb'

    dir = ARGV.shift
    my_lock = ARGV.shift
    other_lock = ARGV.shift

    self.new(dir, my_lock, other_lock).run(*ARGV)
  rescue Shutdown
    $log.debug(self.name.ljust(30) + " shutdown signal received")
  end

  # Initializes communication over the given temporary directory,
  # using the two lock files.
  def initialize(dir, my_lock, other_lock)
    @message_file = "#{dir}/message"
    @shutdown_file = "#{dir}/shutdown"
    @my_lock = "#{dir}/#{my_lock}"
    @other_lock = "#{dir}/#{other_lock}"
    self.log("starting with dir=#{dir}")
  end

  # Logs a debug message prefixed with the name of the bridge.
  def log(message)
    $log.debug(self.class.name.ljust(30) + " " + message)
  end

  # Returns true if the connection has been closed by either
  # end. No further operations should be done. Instead, the
  # initiating partner should now remove the temp directory.
  def shutdown?
    return File.exist?(@shutdown_file)
  end

  # Sends the shutdown signal that closes the connection safely.
  def shutdown
    FileUtils.touch(@shutdown_file)
    self.unlock_the_other()
  end

  # Sends several lines of text to the other end of the bridge.
  def send(*messages)
    raise Shutdown.new if self.shutdown?

    self.log("sending " + messages.inspect)
    File.open(@message_file, "w") do |file|
      messages.each do |message|
        file.puts(message)
      end
    end

    self.log("locking myself, releasing the other")
    self.lock()
    self.unlock_the_other()
  end

  # Waits for my lock to be released.
  def wait()
    while File.exist?(@my_lock)
      raise Shutdown.new if self.shutdown?
      sleep(0.1)
    end
  end

  # Unlocks the other lock.
  def unlock_the_other()
    File.delete(@other_lock)
  end

  # Locks my lock explicitly.
  # Should only be called by the first reader
  # in the very beginning.
  def lock()
    FileUtils.touch(@my_lock)
  end

  # Receives a message from the other end of the bridge.
  def receive()
    raise Shutdown.new if self.shutdown?

    self.log("waiting to read")
    self.wait()
    raise Shutdown.new if self.shutdown?

    self.log("reading")
    answer = File.read(@message_file).split(/\n/).map(&:strip)

    self.log("got " + answer.inspect)
    return answer
  end

  # Raised when the connection was unexpectedly closed by the other
  # end.
  class Shutdown < RuntimeError end

end

