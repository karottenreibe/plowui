require_relative './list_store_iterator.rb'

# Shows all links and their status.
class LinkTable

  # The Gtk widget of the table.
  attr_reader :widget

  def initialize(download_manager)
    @download_manager = download_manager

    @model = Gtk::ListStore.new(Entry, String, String, String, String, String, String)
    @iterator = ListStoreIterator.new(@model)
    @widget = Gtk::TreeView.new(@model)
    @widget.selection.mode = Gtk::SELECTION_MULTIPLE

    renderer = Gtk::CellRendererText.new
    columns = %w{Hoster URL Name Size Status}.each_with_index.map do |label, i|
      column = Gtk::TreeViewColumn.new(label, renderer, :text => i + 1)
      column.expand = true if [1, 4].include?(i)
      @widget.append_column(column)
      column
    end

    columns[4].set_cell_data_func(renderer) do |column, renderer, model, iter|
      foreground = "#000"

      status = iter[0].status
      if status.error?
        foreground = "#f00"
      elsif status.offline?
        foreground = "#999"
      elsif status.online?
        foreground = "#090"
      end

      renderer.foreground = foreground
    end

    @entries = []
  end

  # Returns all selected entries.
  def selected
    entries = []
    @widget.selection.selected_each do |model, path, iter|
      entries << iter[0]
    end
    return entries
  end

  # Adds an entry to the table.
  def add(entry)
    iter = @model.append()
    self.set(iter, entry)
  end

  # Sets the values of the given iter from the entry.
  def set(iter, entry)
    iter[0] = entry
    fields = [entry.hoster, entry.url, entry.name, entry.size, entry.status]
    fields.each_with_index do |item, i|
      iter[i + 1] = item.to_s
    end
  end

  # Removes an entry from the table.
  def remove(entry)
    @iterator.each do |iter|
      if entry == iter[0]
        iter.remove()
        return
      end
    end
  end

  # Removes all useless links, i.e. error and offline links.
  def remove_useless
    @iterator.each do |iter|
      entry = iter[0]
      iter.remove unless entry.status.online? or entry.status.resolving?
    end
  end

  # Updates the model values from the entry
  def update(entry)
    @iterator.each do |iter|
      if entry == iter[0]
        self.set(iter, entry)
        return
      end
    end
  end

  # An entry in the table.
  class Entry

    # The URL of the entry.
    attr_accessor :url

    # The name of the hoster.
    attr_accessor :hoster

    # The file name.
    attr_accessor :name

    # The file size.
    attr_accessor :size

    # The status of the link.
    attr_accessor :status

    def initialize(url)
      @url = url
      @hoster = :resolving
      @name = :resolving
      @size = 0
      @status = Status.new
    end

  end

end

