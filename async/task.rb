require 'thread'

# A task that is executed in a thread.
# Subclasses must implement #run.
class Async::Task

  # The status of the task.
  # Values:
  #   :running when the thread is working
  #   :error on errors
  #   :canceled if the user canceled the task
  #   :success when finished successfully
  #
  # Further values are defined by the subclass.
  #
  # Instead of reading this directly, it is usually
  # better to call methods like #canceled?, #error?
  # and #successful? to get boolean values.
  attr_reader :status

  # An optional message that further describes the
  # status.
  attr_reader :message

  # When the task is done, this contains the result.
  # In case of an error, contains the error message.
  attr_reader :result

  # The user-readable name of the task.
  # Should be set in #run().
  attr_reader :name

  # Starts the task.
  def initialize(*args)
    @status = :running
    @message = nil
    @thread = Thread.new do
      self.run(*args)
    end
  end

  # Violently aborts the thread and sets the status to :canceled
  def cancel
    self.change_status(:canceled)
    @thread.kill
  end

  # Returns true if the thread has stopped.
  def done?
    !@thread.status
  end

  # Returns true if the thread is finished and was successful.
  def successful?
    return @status == :success
  end

  # Returns true if the thread was aborted by the user.
  def canceled?
    return @status == :canceled
  end

  # Returns true if the thread is finished and encountered an error.
  def error?
    return @status == :error
  end

  # Changes the status and result.
  # This method ensures that the result is always set
  # before the status to avoid race conditions.
  # If the given result is nil, the current result will be left
  # unchanged.
  def change_status(status, result = nil, message = nil)
    @result = result if result
    @status = status
    @message = message
  end

end

