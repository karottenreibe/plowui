require_relative './list_store_iterator.rb'

# Shows all running tasks and their status.
class TaskTable

  # The Gtk widget of the table.
  attr_reader :widget

  # The number of seconds an error task is kept in the view.
  TASK_REMOVAL_TIMEOUT = 5

  def initialize()
    @model = Gtk::ListStore.new(Async::Task, String, String)
    @iterator = ListStoreIterator.new(@model)
    @widget = Gtk::TreeView.new(@model)

    renderer = Gtk::CellRendererText.new
    columns = %w{Name Status}.each_with_index.map do |label, i|
      column = Gtk::TreeViewColumn.new(label, renderer, :text => i + 1)
      column.expand = true
      @widget.append_column(column)
      column
    end

    columns[0].set_cell_data_func(renderer) do |column, renderer, model, iter|
      foreground = "#000"

      task = iter[0]
      if task.error?
        foreground = "#f00"
      elsif task.successful?
        foreground = "#090"
      elsif task.canceled?
        foreground = "#999"
      end

      renderer.foreground = foreground
    end

    @tasks = []
    @done_tasks = {}
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
    @iterator.each do |iter|
      task = iter[0]
      if task.done?
        removal_time = @done_tasks[task]
        if not removal_time
          @done_tasks[task] = Time.now + TASK_REMOVAL_TIMEOUT
          @tasks.delete(task)
          self.set(iter, task, TASK_REMOVAL_TIMEOUT)
        elsif Time.now > removal_time
          iter.remove()
          @done_tasks.delete(task)
        else
          time_left = (removal_time - Time.now + 1).to_i
          self.set(iter, task, time_left)
        end
      else
        self.set(iter, task)
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
  # If a time is given in the last parameter, it will be shown
  # as the number of seconds before the task is removed.
  def set(iter, task, time_left = nil)
    status = task.status
    status = "#{status} (#{task.message})" if task.message
    status = "#{status} (#{time_left}s)" if time_left

    iter[0] = task
    iter[1] = task.name
    iter[2] = status
  end

end

