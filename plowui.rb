#!/usr/bin/ruby
require 'rubygems'
require 'bundler'

Bundler.require

require './links_table.rb'

class MainWindow < Gtk::Window

  def initialize
    super

    signal_connect :destroy do 
      Gtk.main_quit
    end

    @table = LinksTable.new
    @table.add(LinksTable::Entry.new("test"))
    @table.add(LinksTable::Entry.new("test2"))
    self.add(@table.widget)
  end

end

Gtk.init
mw = MainWindow.new
mw.show_all
Gtk.main

