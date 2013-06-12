# Represents a link that is in the process of being resolved
# by plowshare, i.e. getting the actual download link.
class Plowshare::Resolvable

  # The orignal link of the resolvable.
  attr_reader :link

  # The file name of the resolvable.
  attr_reader :name

  # The file size of the resolvable.
  attr_reader :size

  # The file size of the resolvable.
  attr_reader :hoster

  def initialize(link, info)
    @link = link
    @name = info[:name]
    @size = info[:size]
    @hoster = info[:hoster]
    self.status = info[:status]
  end

  # Sets the status of the resolvable.
  def status=(status)
    case status
    when :online
      @success = true
      @online = true
    when :offline
      @success = true
      @online = false
    when :error
      @success = false
    end
  end

  # For done links, this returns true if resolving worked
  # and false if an error occurred.
  def success?
    return @success
  end

  # For successfully resolved links, this returns true
  # if the link is online.
  def online?
    return @online
  end

end

