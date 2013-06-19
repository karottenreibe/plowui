# Manages a set of asynchronous tasks.
class Async::TaskManager

  # The given factory must return a new task
  # from its #new method.
  def initialize(task_factory)
    @tasks = {}
    @task_factory = task_class
  end

  # Creates a new task with the given arguments.
  # Starts the task.
  def add(id, *args)
    @tasks[id] = task_factory.new(self, *args)
  end

  # Returns all stored tasks.
  def tasks
    return @tasks.values
  end

  # Returns a map from their id to all done tasks.
  # The returned tasks will be removed from the manager.
  def done
    done_ids = @tasks.keys.find_all do |id|
      @tasks[id].done?
    end
    done_tasks = done_ids.inject({}) do |map, id|
      map[id] = @tasks[id]
      map
    end
    done_ids.each do |id|
      @tasks.remove(id)
    end
    return done_tasks
  end

end

