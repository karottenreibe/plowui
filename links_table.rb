# Shows all links and their status.
class LinksTable

  # The Gtk widget of the table.
  attr_reader :widget

  # The entries of the table.
  attr_reader :entries

  def initialize
    @widget = Gtk::Table.new(1, 3)
    @widget.column_spacings = 10
    @widget.row_spacings = 5
    @entries = []
  end

  # Adds an entry to the table.
  def add(entry)
    @entries << entry
    self.resize_table()
    self.attach_entry(entry, @entries.size - 1)
    @widget.show_all
  end

  # Removes an entry from the table.
  def remove(entry)
    @entries.map(&:widgets).flatten.each do |widget|
      @widget.remove(widget)
    end
    @entries.remove(entry)
    self.resize_table()
    @entries.each_with_index do |entry, row|
      self.attach_entry(entry, row)
    end
    @widget.show_all
  end

  # Resizes the table to match the number of entries.
  def resize_table()
    size = [@entries.size - 1, 1].max
    @widget.resize(size, 3)
  end

  # Adds the given entry's widgets into the given table row.
  def attach_entry(entry, row)
    entry.widgets.each_with_index do |widget, i|
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

    # The status of the link.
    attr_reader :status

    # The Gtk widgets of the entry, which will be inserted as table cells.
    attr_reader :widgets

    def initialize(url)
      @url = url
      @hoster = :unknown
      @status = :unknown

      @hoster_label = Gtk::Label.new(@hoster.to_s)
      @url_label = Gtk::Label.new(@url.to_s)
      @status_label = Gtk::Label.new(@status.to_s)
      @widgets = [@hoster_label, @url_label, @status_label]

      @selected = false
    end

    # Returns true if the entry is selected.
    def selected?
      return @selected
    end

    # Determines whether the item should be selected or not.
    def selected=(selected)
      @selected = selected
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

