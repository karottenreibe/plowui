#!/usr/bin/ruby
require 'rubygems'
require 'bundler'

Bundler.require

require 'logger'
$log = Logger.new(STDOUT)
$log.level = Logger::DEBUG
$log.formatter = proc do |severity, time, program_name, message|
  "#{severity}\t#{message}\n"
end

require './status.rb'
require './clipboard.rb'
require './link_parser.rb'
require './uniqueness_filter.rb'
require './links_table.rb'
require './plowshare.rb'

# The main window of the application.
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
    @api = Plowshare::API.new

    Gtk.idle_add do
      self.check_clipboard
      true
    end

    Gtk.idle_add do
      self.check_resolvers
      true
    end
  end

  # Checks for new links in the clipboard.
  def check_clipboard
    value = @clipboard.read
    return unless value

    links = @parser.parse(value)
    return if links.empty?

    @filter.filter(links) do |link|
      $log.debug("adding #{link}")
      entry = LinksTable::Entry.new(link)
      id = @table.add(entry)
      @api.resolve(link, id)
    end
  end

  # Checks the API for resolver results.
  def check_resolvers
    done_ids = @api.done_ids
    done_ids.each do |id|
      entry = @table.entry(id)
      @table.remove(entry)
    end

    resolvables = @api.results
    resolvables.each do |resolvable|
      entry = LinksTable::Entry.new(resolvable.link)
      entry.status = resolvable.status
      entry.name = resolvable.name
      entry.hoster = resolvable.hoster
      entry.size = resolvable.size
      @table.add(entry)
    end
  end

end

Gtk.init
mw = MainWindow.new
mw.show_all
Gtk.main

