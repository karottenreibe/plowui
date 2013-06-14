# Shows all links and their status.
class LinksTable

  # The Gtk widget of the table.
  attr_reader :widget

  COLUMNS = 6

  def initialize
    @widget = Gtk::Table.new(1, COLUMNS)
    @widget.column_spacings = 10
    @widget.row_spacings = 5

    @entries = []
    @entries_by_id = {}
    @next_id = 0

    @entry_widgets = Hash.new do |hash, key|
      hash[key] = key.widgets + self.create_buttons(key)
    end
  end

  # Creates the download and delete buttons for the given
  # entry.
  def create_buttons(entry)
    delete_button = Gtk::Button.new("\u232B")
    delete_button.signal_connect('clicked') do
      self.remove(entry)
    end

    download_button = Gtk::Button.new("\u21A1")

    return [delete_button, download_button]
  end

  # Adds an entry to the table.
  # Returns the id of the entry.
  def add(entry)
    @entries << entry
    self.resize_table()
    self.attach_entry(entry, @entries.size - 1)
    @widget.show_all

    id = @next_id
    @next_id += 1
    @entries_by_id[id] = entry
    return id
  end

  # Returns the entry for the given ID.
  def entry(id)
    return @entries_by_id[id]
  end

  # Removes an entry from the table.
  def remove(entry)
    @entry_widgets.values.flatten.each do |widget|
      @widget.remove(widget)
    end

    @entries.delete(entry)
    @entry_widgets.delete(entry)
    self.resize_table()

    @entries.each_with_index do |entry, row|
      self.attach_entry(entry, row)
    end
    @widget.show_all
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

    # The Gtk widgets of the entry, which will be inserted as table cells.
    attr_reader :widgets

    def initialize(url)
      @url = url
      @hoster = :"resolving..."
      @name = :"resolving..."
      @size = 0
      @status = Status.new

      @hoster_label = Gtk::Label.new(@hoster.to_s)
      @url_label = Gtk::Label.new(@url.to_s)
      @status_label = Gtk::Label.new(@status.to_s)
      @name_label = Gtk::Label.new(@name.to_s)
      @size_label = Gtk::Label.new(@size.to_s)

      @widgets = [@hoster_label, @url_label, @name_label, @size_label, @status_label]
    end

    # Sets the size.
    def size=(size)
      @size = size
      @size_label.text = @size.to_s
    end

    # Sets the name.
    def name=(name)
      @name = name
      @name_label.text = @name.to_s
    end

    # Sets the URL.
    def url=(url)
      @url = url
      @url_label.text = @url.to_s
    end

    # Sets the hoster.
    def hoster=(hoster)
      @hoster = hoster
      @hoster_label.text = @hoster.to_s
    end

    # Sets the status.
    def status=(status)
      @status = status
      @status_label.text = @status.to_s
    end

  end

end

