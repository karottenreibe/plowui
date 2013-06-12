require 'thread'

# Resolves a resolvable using plowshare.
class Plowshare::Resolver

  # The resolvable that is being resolved.
  attr_reader :resolvable

  # The id associated with the resolver
  attr_reader :id

  def initialize(link, id, api)
    @id = id
    @api = api
    @thread = Thread.new do
      self.resolve(link)
    end
  end

  # Returns true if the resolver is done.
  def done?
    return !@thread.status
  end

  # Run from a thread. Tries to resolve the link.
  def resolve(link)
    $log.debug "starting to resolve #{link}"
    links = @api.list(link)

    if links
      # if it was a folder or crypter, resolve all found links
      links.each do |link|
        self.resolve(link)
      end
    else
      info = @api.probe(link)
      self.push_error_result(link) unless info

      resolvable = Resolvable.new(link, info)
      @api.add_result(resolvable)
    end
  end

  # Pushes an error result for the given link to the api.
  def push_error_result(link)
    info = {
      :name => :unknown,
      :size => 0,
      :hoster => :unknown,
      :status => :error
    }
    resolvable = Resolvable.new(@link, info)
    @api.add_result(resolvable)
  end

end

