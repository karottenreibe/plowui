require_relative '../async.rb'

# Resolves a resolvable using plowshare.
class Plowshare::Resolver < Async::Task

  # Tries to resolve the link.
  def run(link)
    @name = "resolving #{link}"

    @original_link = link
    @api = Plowshare::API.new
    @results = []

    self.resolve(link)
    self.change_status(:success, @results, "resolved")
  end

  # Tries to resolve the link.
  def resolve(link)
    self.debug "starting to resolve #{link}"
    links, status = @api.list(link)
    return self.push_error_result(link, status) unless links or status.can_continue?

    if links
      # if it was a folder or crypter, resolve all found links
      self.debug "folder/crypter contained #{links}. recursing"
      links.each do |link|
        self.resolve(link)
      end
    else
      self.debug "resolving single link #{link}"
      info, status = @api.probe(link)
      return self.push_error_result(link, status) unless info

      self.debug "found #{info}"
      resolvable = Plowshare::Resolvable.new(link, info)
      @results << resolvable
    end
  end

  # Sets an error result for the given link and status.
  # Always returns false.
  def push_error_result(link, status)
    info = {
      :name => :unknown,
      :size => 0,
      :hoster => :unknown,
      :status => status
    }
    resolvable = Plowshare::Resolvable.new(link, info)
    @results << resolvable
  end

  # Sends a debug message to the logger
  def debug(message)
    $log.debug "resolving #{@id}: #{message}"
  end

end

