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

  # The file size of the resolvable.
  attr_reader :status

  def initialize(link, info)
    @link = link
    @name = info[:name]
    @size = info[:size]
    @hoster = info[:hoster]
    @status = info[:status]
  end

end

