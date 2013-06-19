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
require_relative 'link_table.rb'
require_relative 'task_table.rb'
require_relative 'plowshare.rb'
require_relative 'async.rb'

# The main window of the application.
class MainWindow < Gtk::Window

  def initialize
    super

    signal_connect :destroy do
      Gtk.main_quit
    end

    scroller = Gtk::ScrolledWindow.new
    self.add(scroller)

    @download_manager = Async::TaskManager.new(Plowshare::Download)
    @resolver_manager = Async::TaskManager.new(Plowshare::Resolver)

    @link_table = LinkTable.new(@download_manager)
    @task_table = TaskTable.new
    scroller.add_with_viewport(@link_table.widget)

    @clipboard = NonRepeatingClipboard.new
    @parser = LinkParser.new
    @filter = UniquenessFilter.new

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

    Gtk.idle_add do
      self.refresh_task_table
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
      entry = LinkTable::Entry.new(link)
      id = @link_table.add(entry)
      @resolver_manager.add(id, link)
    end
  end

  # Checks the API for resolver results.
  def check_resolvers
    done = @resolver_manager.done
    done.keys.each do |id|
      entry = @link_table.entry(id)
      @link_table.remove(entry)
    end

    resolvables = done.map(&:result).flatten
    resolvables.each do |resolvable|
      entry = LinkTable::Entry.new(resolvable.link)
      entry.status = resolvable.status
      entry.name = resolvable.name
      entry.hoster = resolvable.hoster
      entry.size = resolvable.size
      @link_table.add(entry)
    end
  end

  # Checks if downloads are finished.
  def check_downloads
    @download_manager.done.each do |id,download|
      entry = @link_table.entry(id)
      if attempt.error?
        status = Status.new
        status.error!(attempt.result)
        entry.status = status
      else
        @link_table.remove(entry)
      end
    end
  end

  # Checks if captchas need solving.
  def check_captchas
    downloads = @download_manager.tasks.find_all? do |task|
      task.status == :captcha
    end
    return if downloads.empty?
    # TODO fill and show captcha window, might already be visible!
  end

  # Refreshes the task table from the task managers.
  def refresh_task_table
    @task_table.refresh(@download_manager, @resolver_manager)
  end

end

Gtk.init
mw = MainWindow.new
mw.show_all
Gtk.main

