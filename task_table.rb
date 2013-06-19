# Shows all running tasks and their status.
class TaskTable

  # The Gtk widget of the table.
  attr_reader :widget

  # The number of columns in the table.
  COLUMNS = 6

  def initialize()
    @widget = Gtk::Table.new(1, COLUMNS)
    @widget.column_spacings = 10
    @widget.row_spacings = 5
    @rows = 0
  end

  # Refreshes the table from the given task managers.
  def refresh(*managers)
    self.clear
    managers.each do |manager|
      self.populate(manager)
    end
  end

  # Removes all entries in the table but does not resize it.
  def clear()
    @widget.children.each do |child|
      @widget.remove(child)
    end
    @rows = 0
  end

  # Adds an entry for all tasks in the manager.
  def populate(manager)
    base_index = @rows
    @rows = manager.tasks.size
    self.resize_table()
    manager.tasks.each_with_index do |task, i|
      result = ""
      result = task.result if task.error?
      widgets = [task.name, task.status, result].map do |text|
        Gtk::Label.new(text.to_s)
      end
      self.attach_row(widgets, base_index + i)
    end
  end

  # Attaches the given widgets to the given row.
  def attach_row(widgets, row)
    widgets.each_with_index do |widget, i|
      xflag = Gtk::FILL
      if i == 1 then
        xflag = Gtk::FILL | Gtk::EXPAND
      end
      widget.set_alignment(0, 0.5)
      @widget.attach(widget, i, i + 1, row, row + 1, xflag, Gtk::FILL)
    end
  end

  # Safely resizes the table according to @rows.
  def resize_table
    rows = [@rows, 1].max
    @widget.resize(rows, COLUMNS)
  end

end

