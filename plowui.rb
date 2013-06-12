#!/usr/bin/ruby
require 'rubygems'
require 'bundler'

Bundler.require

require './status.rb'
require './clipboard.rb'
require './link_parser.rb'
require './uniqueness_filter.rb'
require './links_table.rb'

class MainWindow < Gtk::Window

  def initialize
    super

    signal_connect :destroy do
      Gtk.main_quit
    end

    @table = LinksTable.new
    self.add(@table.widget)

    @clipboard = NonRepeatingClipboard.new
    @parser = LinkParser.new
    @filter = UniquenessFilter.new

    Gtk.idle_add do
      self.check_clipboard
      true
    end
  end

  # Checks for new links in the clipboard
  def check_clipboard
    value = @clipboard.read
    return unless value
    links = @parser.parse(value)
    return if links.empty?
    @filter.filter(links) do |link|
      entry = LinksTable::Entry.new(link)
      @table.add(entry)
    end
  end

end

Gtk.init
mw = MainWindow.new
mw.show_all
Gtk.main

