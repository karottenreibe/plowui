# Represents the online/offline status of a link.
class Status

  def initialize
    @status = :unknown
  end

  # Set it to offline.
  def offline!
    @status = :offline
  end

  # Set it to online.
  def online!
    @status = :online
  end

  def to_s
    @status.to_s
  end

end
