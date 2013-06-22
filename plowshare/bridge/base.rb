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
class Plowshare::Bridge::Base

  def initialize(dir, my_lock, other_lock)
    @message_file = "#{dir}/message"
    @my_lock = "#{dir}/#{my_lock}"
    @other_lock = "#{dir}/#{other_lock}"
    log("starting with dir=#{dir}")
  end

  def log(message)
    File.open("/tmp/log", "a") do |f|
      f.puts self.class.name.ljust(30) + " " + message
    end
  end

  # Sends several lines of text to the other end of the bridge.
  def send(*messages)
    log("sending " + messages.inspect)
    File.open(@message_file, "w") do |file|
      messages.each do |message|
        file.puts(message)
      end
    end
    log("locking myself, releasing the other")
    self.lock_me_unlock_the_other()
  end

  # Waits for my lock to be released.
  def wait()
    sleep(0.1) while File.exist?(@my_lock)
  end

  # Locks my lock, then unlocks the other lock.
  def lock_me_unlock_the_other()
    self.lock()
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
    log("waiting to read")
    self.wait()
    log("reading")
    answer = File.read(@message_file).split(/\n/).map(&:strip)
    log("got " + answer.inspect)
    return answer
  end

end

