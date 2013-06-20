# Shows all running tasks and their status.
class TaskTable

  # The Gtk widget of the table.
  attr_reader :widget

  def initialize()
    @model = Gtk::ListStore.new(Async::Task, String, String)
    @widget = Gtk::TreeView.new(@model)

    renderer = Gtk::CellRendererText.new
    %w{Name Status}.each_with_index do |label, i|
      column = Gtk::TreeViewColumn.new(label, renderer, :text => i + 1)
      column.expand = true
      @widget.append_column(column)
    end

    @tasks = []
  end

  # Returns all selected tasks.
  def selected
    tasks = []
    @widget.selection.selected_each do |model, path, iter|
      tasks << iter[0]
    end
    return tasks
  end

  # Refreshes the table from the given task managers.
  def refresh(*managers)
    iter = @model.iter_first
    valid = !iter.nil?
    while valid
      task = iter[0]
      if task.done?
        valid = @model.remove(iter)
        @tasks.delete(task)
      else
        self.set(iter, task)
        valid = iter.next!
      end
    end

    tasks = managers.map(&:tasks).flatten
    tasks_to_add = tasks - @tasks
    self.add(tasks_to_add)
  end

  # Adds an entry for all tasks.
  def add(tasks)
    tasks.each do |task|
      iter = @model.append()
      self.set(iter, task)
    end
    @tasks += tasks
  end

  # Sets the given iterator's values from the given task.
  def set(iter, task)
    status = task.status
    status = "#{status} (#{task.result})" if task.error?

    iter[0] = task
    iter[1] = task.name
    iter[2] = status
  end

end

