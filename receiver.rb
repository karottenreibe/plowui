# Receivers get the final download link and cookies
# and handle the actual act of downloading it.
module Receiver

  # Base class for receivers that creates the download button.
  class Base

    # The name of the receiver.
    attr_reader :name

    # The button which will trigger this receiver.
    attr_reader :button

    def initialize(name)
      @name = name
      @button = Gtk::Button.new()
    end

    # Updates the button text based on the #online? status
    # of the receiver.
    def update_button()
      if self.online?
        @button.label = "\u21A1 with #{@name}"
        @button.sensitive = true
      else
        @button.label = "#{@name} is offline"
        @button.sensitive = false
      end
    end

    # Returns an entry wrapper for the given entry.
    def wrap(entry)
      wrapper = EntryWrapper.new
      wrapper.entry = entry
      wrapper.receiver = self
      return wrapper
    end

  end

  # Stores an entry and the receiver used to download it.
  class EntryWrapper

    # The downloaded entry.
    attr_accessor :entry

    # The receiver used to download it.
    attr_accessor :receiver

  end

end

require_relative './receiver/aria.rb'
require_relative './receiver/mplayer.rb'

