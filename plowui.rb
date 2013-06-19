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

require_relative 'status.rb'
require_relative 'clipboard.rb'
require_relative 'link_parser.rb'
require_relative 'uniqueness_filter.rb'
require_relative 'links_table.rb'
require_relative 'plowshare.rb'

# The main window of the application.
class MainWindow < Gtk::Window

  def initialize
    super

    signal_connect :destroy do
      Gtk.main_quit
    end

    scroller = Gtk::ScrolledWindow.new
    self.add(scroller)

    @table = LinksTable.new
    scroller.add_with_viewport(@table.widget)

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

    Gtk.idle_add do
      self.check_downloads
      true
    end

    Gtk.idle_add do
      self.check_captchas
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
    @api.resolved_ids.each do |id|
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

  # Checks if downloads are finished.
  def check_downloads
    @api.done_attempts.each do |attempt|
      entry = @table.entry(attempt.id)
      if attempt.error
        status = Status.new
        status.error!(error)
        entry.status = status
      else
        @table.remove(entry)
      end
    end
  end

  # Checks if captchas need solving.
  def check_captchas
    attempts = @api.captcha_attempts
    return if attempts.empty?
    # TODO fill and show captcha window, might already be visible!
  end

end

Gtk.init
mw = MainWindow.new
mw.show_all
Gtk.main

