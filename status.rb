# Represents the online/offline status of a link.
class Status

  def initialize
    @status = :resolving
    @message = nil
    @can_continue = true
  end

  # Set it to offline.
  def offline!(reason = nil)
    @status = :offline
    @message = reason
    @can_continue = false
  end

  # Set it to online.
  def online!
    @status = :online
    @message = nil
    @can_continue = true
  end

  # Set it to error.
  def error!(reason = nil, can_continue = false)
    @status = :error
    @message = reason
    @can_continue = can_continue
  end

  # Returns true if the link was reported as bad by plowlist
  # but should still be probed by plowprobe
  def can_continue?
    @can_continue
  end

  # Returns true if the link is currently being resolved.
  def resolving?
    @status == :resolving
  end

  # Returns true if the link is definitely online.
  def online?
    return @status == :online
  end

  # Returns true if the link is definitely offline.
  def offline?
    return @status == :offline
  end

  # Returns true if an error occurred during resolution.
  def error?
    return @status == :error
  end

  def to_s
    str = @status.to_s
    str += " (#{@message})" if @message
    return str
  end

  # Creates a new status from a plowshare status value.
  def self.from_plowshare(plowshare_status)
    status = Status.new
    return unless plowshare_status

    normalized_status = plowshare_status % 100

    case normalized_status
    when 0 then status.online!
    when 1 then status.error!("module out of date", true)
    when 2 then status.error!("not supported", true)
    when 3 then status.error!("network error", true)
    when 3 then status.error!("login failed")
    when 5, 6 then status.error!("timeout", true)
    when 7 then status.error!("captcha error")
    when 8 then status.error!("bug in the module", true)
    when 10 then status.offline!("temporarily unavailable")
    when 11 then status.error!("needs password")
    when 12 then status.error!("requires authentication")
    when 13 then status.offline!
    when 14 then status.error!("file too big")
    when 15 then status.error!("bug in plowui", true)
    else status.error!("unknown error code #{plowshare_status}")
    end

    return status
  end

end
