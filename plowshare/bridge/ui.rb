require './base.rb'

# The bridge on the UI side.
class UIBridge < BridgeBase

  def initialize(fifo_in, fifo_out)
    super(nil, fifo_in, fifo_out)
  end

end

