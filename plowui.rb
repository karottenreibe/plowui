#!/usr/bin/ruby
require 'rubygems'
require 'bundler'

Bundler.require

require_relative 'init.rb'

require_relative 'status.rb'
require_relative 'clipboard.rb'
require_relative 'link_parser.rb'
require_relative 'uniqueness_filter.rb'
require_relative 'link_table.rb'
require_relative 'task_table.rb'
require_relative 'captcha_window.rb'
require_relative 'async.rb'
require_relative 'plowshare.rb'
require_relative 'aria.rb'

# The main window of the application.
class MainWindow < Gtk::Window

  def initialize
    super

    signal_connect :destroy do
      Gtk.main_quit
    end

    @captcha_window = CaptchaWindow.new
    @aria = Aria.new($options.aria)

    main_table = Gtk::Table.new(5, 1)
    self.add(main_table)

    main_table.attach(self.create_link_header(), 0, 1, 0, 1, Gtk::FILL, Gtk::FILL, 0, 10)
    link_scroller = Gtk::ScrolledWindow.new
    main_table.attach(link_scroller, 0, 1, 1, 3, Gtk::EXPAND | Gtk::FILL, Gtk::EXPAND | Gtk::FILL)

    main_table.attach(self.create_task_header(), 0, 1, 3, 4, Gtk::FILL, Gtk::FILL, 0, 10)
    task_scroller = Gtk::ScrolledWindow.new
    main_table.attach(task_scroller, 0, 1, 4, 5, Gtk::EXPAND | Gtk::FILL, Gtk::EXPAND | Gtk::FILL)

    @download_manager = Async::TaskManager.new(Plowshare::Download)
    @resolver_manager = Async::TaskManager.new(Plowshare::Resolver)

    @link_table = LinkTable.new(@download_manager)
    link_scroller.add_with_viewport(@link_table.widget)
    @task_table = TaskTable.new
    task_scroller.add_with_viewport(@task_table.widget)

    @clipboard = NonRepeatingClipboard.new
    @parser = LinkParser.new
    @filter = UniquenessFilter.new

    self.idle(:check_clipboard)
    self.idle(:check_resolvers)
    self.idle(:check_downloads)
    self.idle(:check_captchas)
    self.idle(:refresh_task_table)
    self.idle(:update_download_button)
  end

  # Returns the header widget above the link table.
  def create_link_header()
    hbox = Gtk::HBox.new

    label = Gtk::Label.new("Found Links")
    hbox.pack_start(label, false)

    @download_button = Gtk::Button.new()
    @download_button.signal_connect(:clicked) do
      @link_table.selected.each do |entry|
        @download_manager.add(entry, entry.url)
      end
    end
    hbox.pack_end(@download_button, false)

    delete_button = Gtk::Button.new("\u2718")
    delete_button.set_size_request(50, -1)
    delete_button.signal_connect(:clicked) do
      @link_table.selected.each do |entry|
        @link_table.remove(entry)
      end
    end
    hbox.pack_end(delete_button, false)

    delete_useless_button = Gtk::Button.new("\u2718 useless links")
    delete_useless_button.signal_connect(:clicked) do
      @link_table.remove_useless
    end
    hbox.pack_end(delete_useless_button, false, true, 50)

    return hbox
  end

  # Returns the header widget above the link table.
  def create_task_header()
    hbox = Gtk::HBox.new

    label = Gtk::Label.new("Running Tasks")
    hbox.pack_start(label, false)

    cancel_button = Gtk::Button.new("\u2718")
    cancel_button.set_size_request(50, -1)
    cancel_button.signal_connect(:clicked) do
      @task_table.selected.each do |task|
        task.cancel()
      end
    end
    hbox.pack_end(cancel_button, false)

    return hbox
  end

  # Adds a new idle function with the given name.
  def idle(name)
    Gtk.idle_add do
      self.send(name)
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
      @link_table.add(entry)
      @resolver_manager.add(entry, link)
    end
  end

  # Checks the API for resolver results.
  def check_resolvers
    done = @resolver_manager.done
    done.each do |entry, resolver|
      if resolver.successful?
        @link_table.remove(entry)

        resolver.result.each do |resolvable|
          entry = LinkTable::Entry.new(resolvable.link)
          entry.status = resolvable.status
          entry.name = resolvable.name
          entry.hoster = resolvable.hoster
          entry.size = resolvable.size
          @link_table.add(entry)
        end
      else
        entry.status.error!(resolver.message)
        @link_table.update(entry)
      end
    end
  end

  # Checks if downloads are finished.
  def check_downloads
    @download_manager.done.each do |entry, download|
      if download.error?
        entry.status.error!(download.message)
        @link_table.update(entry)
      else
        result = download.result
        if @aria.add(result[:url], result[:file], result[:cookies])
          @link_table.remove(entry)
          download.change_status(:success, nil, "added to aria")
        else
          download.change_status(:error, nil, "could not add URL to aria")
        end
      end
    end
  end

  # Checks if captchas need solving.
  def check_captchas
    downloads = @download_manager.tasks.find_all do |task|
      task.status == :captcha and not task.solving
    end
    return if downloads.empty?

    downloads.each do |download|
      @captcha_window.solve(download.url, download.result) do |solution|
        download.solved_captcha(solution)
      end
      download.solving = true
    end
  end

  # Refreshes the task table from the task managers.
  def refresh_task_table
    @task_table.refresh(@download_manager, @resolver_manager)
  end

  # Updates the state of the download button based on whether aria is online.
  def update_download_button
    if @aria.online?
      @download_button.label = "\u21A1"
      @download_button.set_size_request(50, -1)
      @download_button.sensitive = true
    else
      @download_button.label = "Aria2 is offline"
      @download_button.set_size_request(-1, -1)
      @download_button.sensitive = false
    end
  end

end

Gtk.init
mw = MainWindow.new
mw.show_all
Gtk.main

