require 'set'

# Makes sure no double entires are added to the table.
class UniquenessFilter

  def initialize
    @set = Set.new
  end

  # Filters out all links that are already present and
  # calls the block with every link that should
  # actually be added.
  def filter(links)
    link_set = Set.new(links)
    (link_set - @set).each do |link|
      yield(link)
    end
    @set += link_set
  end

  # Used to notify the filter that the given links have
  # been removed.
  def onRemoved(links)
    @set -= links
  end

end

