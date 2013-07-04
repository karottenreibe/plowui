#!/usr/bin/ruby
Dir.chdir(File.dirname(__FILE__))
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
require_relative 'receiver.rb'

# The main window of the application.
class MainWindow < Gtk::Window

  def initialize
    super

    signal_connect :destroy do
      Gtk.main_quit
    end

    accels = Gtk::AccelGroup.new
    accels.connect(Gdk::Keyval::GDK_Q, Gdk::Window::CONTROL_MASK, Gtk::ACCEL_VISIBLE) do
      Gtk.main_quit
    end
    add_accel_group(accels)

    @captcha_window = CaptchaWindow.new
    @receivers = [
      Receiver::Aria.new($options.aria),
      Receiver::MPlayer.new($options.mplayer),
      Receiver::VLC.new($options.vlc),
    ]

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

    GLib::Timeout.add(500) do
      self.perform_background_tasks
      true
    end
  end

  # Executed regularly by a timeout to perform background tasks
  def perform_background_tasks
    self.check_clipboard
    self.check_resolvers
    self.check_downloads
    self.check_captchas
    self.refresh_task_table
    self.update_download_buttons
  end

  # Returns the header widget above the link table.
  def create_link_header()
    hbox = Gtk::HBox.new

    label = Gtk::Label.new("Found Links")
    hbox.pack_start(label, false)

    @receivers.each do |receiver|
      receiver.button.signal_connect(:clicked) do
        @link_table.selected.each do |entry|
          @download_manager.add(receiver.wrap(entry), entry.url)
        end
      end
      hbox.pack_end(receiver.button, false)
    end

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
    @download_manager.done.each do |wrapper, download|
      entry = wrapper.entry
      receiver = wrapper.receiver
      if download.error?
        entry.status.error!(download.message)
        @link_table.update(entry)
      elsif download.successful?
        result = download.result
        if receiver.add(result[:url], result[:name], result[:cookies])
          download.change_status(:success, nil, "added to #{receiver.name}")
        else
          download.change_status(:error, nil, "could not add URL to #{receiver.name}")
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
  def update_download_buttons
    @receivers.each do |receiver|
      receiver.update_button()
    end
  end

end

Gtk.init
mw = MainWindow.new
mw.show_all
Gtk.main

