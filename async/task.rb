# A task that is executed in a thread.
# Subclasses must implement #run.
class Async::Task

  # The status of the task.
  # Values:
  #   :running when the thread is working
  #   :error on errors
  #   :success when finished successfully
  #
  # Further values are defined by the subclass.
  attr_reader :status

  # When the task is done, this contains the result.
  # In case of an error, contains the error message.
  attr_reader :result

  # Starts the task.
  def initialize(task_manager, *args)
    @manager = task_manager
    @status = :running
    @thread = Thread.new do
      self.run(*args)
    end
  end

  # Returns true if the thread has stopped.
  def done?
    !@thread.status
  end

  # Returns true if the thread is finished and was successful.
  def successful?
    return @status == :success
  end

  # Returns true if the thread is finished and encountered an error.
  def error?
    return @status == :error
  end

end

