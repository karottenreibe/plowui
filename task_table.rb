# Shows all running tasks and their status.
class TaskTable

  # The Gtk widget of the table.
  attr_reader :widget

  def initialize()
    @model = Gtk::ListStore.new(String, String)
    @widget = Gtk::TreeView.new(@model)

    renderer = Gtk::CellRendererText.new
    %w{Name Status}.each_with_index do |label, i|
      column = Gtk::TreeViewColumn.new(label, renderer, :text => i)
      column.expand = true
      @widget.append_column(column)
    end
  end

  # Refreshes the table from the given task managers.
  def refresh(*managers)
    @model.clear()
    tasks = managers.map(&:tasks).flatten
    self.populate(tasks)
  end

  # Adds an entry for all tasks.
  def populate(tasks)
    tasks.each do |task|
      status = task.status
      status = "#{status} (#{task.result})" if task.error?

      iter = @model.append()
      iter[0] = task.name
      iter[1] = status
    end
  end

end

