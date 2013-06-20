# Lets the user solve captchas.
class CaptchaWindow < Gtk::Window

  def initialize
    super
    self.set_size_request(400, 300)

    vbox = Gtk::VBox.new
    self.add(vbox)

    @label = Gtk::Label.new
    vbox.pack_start(@label, false)

    @image = Gtk::Image.new
    vbox.pack_start(@image, true)

    @entry = Gtk::Entry.new
    vbox.pack_start(@entry, false)
    @entry.activates_default = true
    @entry.grab_focus()

    hbox = Gtk::HBox.new
    vbox.pack_start(hbox, false)

    submit_button = Gtk::Button.new("Submit")
    hbox.pack_end(submit_button, false)
    submit_button.signal_connect(:clicked) do
      self.submit()
    end
    submit_button.can_default = true
    submit_button.grab_default()

    retry_button = Gtk::Button.new("Retry")
    hbox.pack_end(retry_button, false)
    retry_button.signal_connect(:clicked) do
      self.retry()
    end

    cancel_button = Gtk::Button.new("Cancel")
    hbox.pack_end(cancel_button, false)
    cancel_button.signal_connect(:clicked) do
      self.cancel()
    end

    self.signal_connect(:"key-press-event") do |window, event|
      if event.keyval == Gdk::Keyval::GDK_Escape
        self.cancel()
      end
    end

    @captchas = []
  end

  # Aborts solving for the current url.
  def cancel
    self.solved(:abort)
  end

  # Asks for another captcha image from the current url.
  def retry
    self.solved(:retry)
  end

  # Submits a solution for the current url.
  def submit
    solution = @entry.text
    return self.retry() if solution.empty?
    self.solved(solution)
  end

  # Sends the solution and resets the view.
  def solved(solution)
    @entry.text = ""
    captcha = @captchas.delete(0)
    captcha[:callback].call(solution)
    self.refresh()
  end

  # Adds a file to the list of captchas to solve.
  # The given block will be called once the user solved the captcha.
  # The argument will be any of the following:
  #
  #   the entered solution as a string
  #   :retry if the user wants to retry with another image
  #   :abort if the user wants to stop solving captchas for the link
  def solve(url, captcha_path, &callback)
    @captchas << {
      :file => captcha_path,
      :url => url,
      :callback => callback
    }

    self.refresh()
    self.show_all()
  end

  # Displays the image file of the current captcha
  # and updates the label.
  # If no captchas are left, hides the window.
  def refresh
    captcha = @captchas.first
    if captcha.nil?
      self.hide
      return
    end

    @image.set_from_file(captcha[:file])
    @label.text = "Captcha for #{captcha[:url]} (#{@captchas.size} left)"
    self.show_all
  end

end

