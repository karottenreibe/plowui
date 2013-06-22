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
#
# Subclasses of an external bridge must implement #run
# in which they must perform their communication.
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
  end

  # Initializes communication over the given temporary directory,
  # using the two lock files.
  def initialize(dir, my_lock, other_lock)
    @message_file = "#{dir}/message"
    @my_lock = "#{dir}/#{my_lock}"
    @other_lock = "#{dir}/#{other_lock}"
    self.log("starting with dir=#{dir}")
  end

  # Logs a debug message prefixed with the name of the bridge.
  def log(message)
    $log.debug(self.class.name.ljust(30) + " " + message)
  end

  # Sends several lines of text to the other end of the bridge.
  def send(*messages)
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
    sleep(0.1) while File.exist?(@my_lock)
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
    self.log("waiting to read")
    self.wait()

    self.log("reading")
    answer = File.read(@message_file).split(/\n/).map(&:strip)

    self.log("got " + answer.inspect)
    return answer
  end

end

