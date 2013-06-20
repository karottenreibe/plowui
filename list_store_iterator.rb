# Allows removal of rows from a Gtk::ListStore
# while iterating it in Ruby fashion.
class ListStoreIterator

  # Creates a new iterator for the given store.
  def initialize(store)
    @store = store
  end

  # Iterates over each row, yielding the iterator
  # for it.
  def each
    @iter = @store.iter_first
    @valid = !@iter.nil?
    while @valid
      @removed = false
      yield(self)
      @valid = @iter.next! unless @removed
    end
  end

  # Accesses the data at the given key.
  def [](key)
    return @iter[key]
  end

  # Sets the data at the given key.
  def []=(key, value)
    @iter[key] = value
  end

  # Removes the current row.
  def remove
    @valid = @store.remove(@iter)
    @removed = true
  end

end

