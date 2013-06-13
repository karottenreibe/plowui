# Represents the online/offline status of a link.
class Status

  def initialize
    @status = :unknown
    @message = nil
  end

  # Set it to offline.
  def offline!(reason = nil)
    @status = :offline
    @message = reason
  end

  # Set it to online.
  def online!
    @status = :online
    @message = nil
  end

  # Set it to error.
  def error!(reason = nil)
    @status = :error
    @message = reason
  end

  def to_s
    str = @status.to_s
    str += " (#{@message})" if @message
    return str
  end

  # Creates a new status from a plowshare status value.
  def self.from_plowshare(plowshare_status)
    status = Status.new

    plowshare_status %= 100

    case plowshare_status
    when 0 then status.online!
    when 1 then status.error!("module out of date")
    when 2 then status.error!("not supported")
    when 3 then status.error!("network error")
    when 3 then status.error!("login failed")
    when 5, 6 then status.error!("timeout")
    when 7 then status.error!("captcha error")
    when 8 then status.error!("bug in the module")
    when 10 then status.offline!("temporarily unavailable")
    when 11 then status.error!("temporarily unavailable")
    when 12 then status.error!("requires authentication")
    when 13 then status.offline!
    when 14 then status.error!("file too big")
    when 15 then status.error!("bug in plowui")
    else status.error!("unknown error code #{plowshare_status}")
    end

    return status
  end

end
