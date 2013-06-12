# Reads values from the clipboard, but ignores the last seen value
class NonRepeatingClipboard

  def initialize
    @last_value = nil
  end

  # Returns the value in the clipboard or nil if none was found
  def read()
    value = %x{sh -c "xclip -out -selection c 2> /dev/null"}
    return nil if value == @last_value
    @last_value = value
    return value
  end

end

