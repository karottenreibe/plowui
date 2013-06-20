# Shows all links and their status.
class LinkTable

  # The Gtk widget of the table.
  attr_reader :widget

  def initialize(download_manager)
    @download_manager = download_manager

    @model = Gtk::ListStore.new(TrueClass, String, String, String, String, String, Entry)
    @widget = Gtk::TreeView.new(@model)

    toggle_renderer = Gtk::CellRendererToggle.new
    toggle_renderer.signal_connect("toggled") do |renderer, path|
      iter = @model.get_iter(path)
      iter[0] = !iter[0]
    end
    column = Gtk::TreeViewColumn.new("", toggle_renderer, :active => 0)
    @widget.append_column(column)

    renderer = Gtk::CellRendererText.new
    columns = %w{Hoster URL Name Size Status}.each_with_index.map do |label, i|
      column = Gtk::TreeViewColumn.new(label, renderer, :text => i + 1)
      column.expand = true if [1, 4].include?(i)
      @widget.append_column(column)
      column
    end

    @entries = []
  end

  # Returns all selected entries.
  def selected
    selected_entries = []

    iter = @model.get_iter_first()
    loop do
      selected_entries << iter[6] if iter[0]
      break unless iter.next!
    end

    return selected_entries
  end

  # Creates the download and delete buttons for the given
  # entry.
  def create_buttons(entry) # TODO
    delete_button = Gtk::Button.new("\u232B")
    delete_button.signal_connect('clicked') do
      self.remove(entry)
    end

    download_button = Gtk::Button.new("\u21A1")
    download_button.signal_connect('clicked') do
      @download_manager.add(entry.url)
    end

    return [delete_button, download_button]
  end

  # Adds an entry to the table.
  def add(entry)
    iter = @model.append()
    iter[0] = false
    iter[1] = entry.hoster.to_s
    iter[2] = entry.url.to_s
    iter[3] = entry.name.to_s
    iter[4] = entry.size.to_s
    iter[5] = entry.status.to_s
    iter[6] = entry
  end

  # Removes an entry from the table.
  def remove(entry)
    @entries.delete(entry)
    self.refresh()
  end

  # Removes and re-adds all entries from the model.
  def refresh()
    @model.clear
    @entries.each do |id|
      self.add(entry)
    end
  end

  # Resizes the table to match the number of entries.
  def resize_table()
    size = [@entries.size - 1, 1].max
    @widget.resize(size, COLUMNS)
  end

  # Adds the given entry's widgets into the given table row.
  def attach_entry(entry, row)
    @entry_widgets[entry].each_with_index do |widget, i|
      xflag = Gtk::FILL
      if i == 1 then
        xflag = Gtk::FILL | Gtk::EXPAND
      end
      widget.set_alignment(0, 0.5)
      @widget.attach(widget, i, i + 1, row, row + 1, xflag, Gtk::FILL)
    end
  end

  # An entry in the table.
  class Entry

    # The URL of the entry.
    attr_reader :url

    # The name of the hoster.
    attr_reader :hoster

    # The file name.
    attr_reader :name

    # The file size.
    attr_reader :size

    # The status of the link.
    attr_reader :status

    # The tree view this entry is associated with.
    attr_accessor :tree_view

    def initialize(url)
      @url = url
      @hoster = :"resolving..."
      @name = :"resolving..."
      @size = 0
      @status = Status.new
      @tree_view = nil
    end

    # Causes the tree view to refresh.
    def refresh
      @tree_view.refresh() if @tree_view
    end

    # Sets the size.
    def size=(size)
      @size = size
      self.refresh()
    end

    # Sets the name.
    def name=(name)
      @name = name
      self.refresh()
    end

    # Sets the URL.
    def url=(url)
      @url = url
      self.refresh()
    end

    # Sets the hoster.
    def hoster=(hoster)
      @hoster = hoster
      self.refresh()
    end

    # Sets the status.
    def status=(status)
      @status = status
      self.refresh()
    end

  end

end

