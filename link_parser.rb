class LinkParser

  # Extracts all interesting links from a snippet of text.
  def parse(text)
    return text.scan(/(?:https?\:\/\/|www.)[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,3}(?:\/\S*)?/).uniq
  end

end

