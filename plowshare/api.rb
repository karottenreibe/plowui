# Class for interfacing with plowshare's executables.
class PlowShare::API

  def initialize
    @resolvers = []
    @resolvables = []
    @mutex = Mutex.new
  end

  # Starts a thread that resolves the given link.
  def resolve(link, id)
    resolver = Resolver.new(link, id, self)
    @resolvers << resolver
  end

  # Adds a resolvable to the result list.
  def add_result(resolvable)
    @mutex.synchronize do
      @resolvables << resolvable
    end
  end

  # Returns all IDs that have been resolved.
  def done_ids
    done_resolvers = @resolvers.find_all(&:done?)
    @resolvers.reject! do |resolver|
      done_resolvers.include?(resolver)
    end
    return done_resolvers.map(&:id)
  end

  # Returns all done resolvables.
  def results
    @mutex.synchronize do
      resolvables = @resolvables
      @resolvables = []
      return resolvables
    end
  end

  # Call plowlist to resolve folders and crypters.
  # If links were found, returns them as an array.
  # Otherwise returns nil.
  def list(link)
  end

  # Call plowprobe to get info about a link.
  # Returns the gathered info.
  # If an error occurred, returns nil.
  def probe(link)
  end

  # Call plowdown to obtain a download link.
  # Returns the download link.
  # If an error occurred, returns nil.
  #
  # If entering a captcha is required, calls the
  # callback.
  def down(link, captcha_callback)
  end

end

