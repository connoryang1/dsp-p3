using Gtk, Dates, PortAudio

include("synthwrite.jl")
include("transcriber.jl")
# include("recording.jl")

NUM_ROWS = 6
NUM_COLS = 35
WRAP = false
styles = GtkCssProvider(data="
  * {
    font-family: Tahoma;
  }
  #header {
    padding: 5px;
    font-size: 20px;
    margin: 10px;
    font-weight: bold;
  }
  #export-button {
    padding: 5px;
    font-size: 20px;
    margin: 10px;
    background: transparent;
  }
  #wrap-button {
    padding: 10px;
    font-size: 15px;
    margin: 5px;
    background: transparent;
  }
  #note {
    padding: 5px 15px 5px 5px;
    font-size: 25px;
    font-weight: bold;
  }
  #input {
    background: transparent;
    font-size: 20px;
    border: none;
    border-radius: 0;
    caret-color: transparent;
  }
  #input:focus {
    background: #f0f0f0;
  }
  #tempo-button {
    padding: 3px;
    font-size: 20px;
    background: transparent;
    border-radius: 0;
    border: none;
  }
  #header-box {
  }
")

mutable struct MyState
  task::Union{Task,Nothing}
  someCounter::Int
end

function styled(widget, name)
  push!(GAccessor.style_context(widget), GtkStyleProvider(styles), 600)
  set_gtk_property!(widget, :name, name)
end

function async_set(obj, str)
  @sigatom @async begin
    @sigatom set_gtk_property!(obj, :text, str)
  end
end

function get_index_of(widget, grid)
  for i in range(1, NUM_ROWS)
    for j in range(1, NUM_COLS)
      if grid[j, i] == widget
        return (i, j)
      end
    end
  end
  return (0, 0)
end

function create_main_window()
  win = GtkWindow("Home")
  set_gtk_property!(win, :window_position, Gtk.GtkWindowPosition.CENTER)
  vbox_main = GtkBox(:v)
  image = GtkImage("logo2.png")

  transcriber = GtkButton("Transcriber")
  synthesizer = GtkButton("Synthesizer")
  hbox_main = GtkBox(:h)
  # set_gtk_property!(hbox_main, :spacing, 10)
  push!(vbox_main, image)
  push!(hbox_main, transcriber)
  push!(hbox_main, synthesizer)
  push!(vbox_main, hbox_main)
  push!(win, vbox_main)
  showall(win)

  signal_connect(transcriber, "clicked") do _
    create_transcriber_window()
    Gtk.destroy(win)
  end

  signal_connect(synthesizer, "clicked") do _
    create_synth_window()
    Gtk.destroy(win)
  end
end

function create_synth_window()

  playing = false
  reproduction_speed = 1

  header = styled(GtkLabel("Synthesizer"), "header")
  import_button = styled(GtkButton("Import"), "export-button")
  wrap_button = styled(GtkButton("Wrap"), "export-button")
  play_button = styled(GtkButton("Play"), "export-button")
  back_button = styled(GtkButton("Back"), "export-button")
  export_button = styled(GtkButton("Export"), "export-button")
  clear_button = styled(GtkButton("Clear"), "export-button")
  increase_tempo_button = styled(GtkButton("+"), "export-button")
  decrease_tempo_button = styled(GtkButton("-"), "export-button")
  tempo_label = styled(GtkLabel("1.0"), "header")
  tablature = styled(GtkGrid(), "grid")
  note_labels = styled(GtkGrid(), "grid")
  sidebar = styled(GtkBox(:v), "sidebar")
  # history_scroll = styled(GtkScrolledWindow(), "scroll-window")
  # history_list = GtkListStore

  notes = ["e", "B", "G", "D", "A", "E"]

  for i in range(1, NUM_ROWS)
    note = styled(GtkLabel(notes[i]), "note")

    for j in range(1, NUM_COLS)
      local entry = styled(GtkEntry(), "input")
      set_gtk_property!(entry, :width_chars, 2)
      set_gtk_property!(entry, :xalign, 0.5)
      set_gtk_property!(entry, :placeholder_text, "-")

      function on_insert_text(ent, text, _, _)

        row, _ = get_index_of(ent, tablature)
        curr_text = get_gtk_property(ent, :text, String)
        allowed_chars = ['0', '1', '2', '3', '4']
        allowed_last = [allowed_chars; ['5', '6', '7', '8', '9']]
        is_allowed = ((row == 1) ?
                      all(c -> c in allowed_last, text) :
                      all(c -> c in allowed_chars, text)) && text != ""

        if (is_allowed)

          # Clear column
          async_set(ent, text) # This has to be run before below sets for some reason?

          for k in range(1, NUM_ROWS)
            if k != i
              temp_ent = tablature[j, k]
              async_set(temp_ent, "")
            end
          end

        else
          # Invalid input
          async_set(ent, curr_text)
        end
      end

      function on_key_press(widget, event)
        row, col = get_index_of(widget, tablature)

        if (event.keyval == 65288) # Delete
          async_set(widget, "")

        elseif (event.keyval == 65361) # Left
          new_col = WRAP ?
                    (
            (col == 2) ?
            NUM_COLS :
            col - 1
          ) : max(2, col - 1)

          Gtk.grab_focus(tablature[new_col, row])

        elseif (event.keyval == 65362) # Up
          new_row = WRAP ? (
            (row == 1) ?
            NUM_ROWS :
            row - 1
          ) : max(1, row - 1)

          Gtk.grab_focus(tablature[col, new_row])

        elseif (event.keyval == 65363) # Right
          new_col = WRAP ? (
            (col == NUM_COLS) ?
            2 :
            col + 1
          ) : min(NUM_COLS, col + 1)
          Gtk.grab_focus(tablature[new_col, row])

        elseif (event.keyval == 65364) # Down
          new_row = WRAP ? (
            (row == NUM_ROWS) ?
            1 :
            row + 1) : min(NUM_ROWS, row + 1)
          Gtk.grab_focus(tablature[col, new_row])

        elseif (event.keyval >= 48 && event.keyval <= 57)
          return false
        end
        return true
      end
      signal_connect(on_insert_text, entry, "insert-text")
      signal_connect(on_key_press, entry, "key-press-event")
      tablature[j, i] = entry
    end

    note_labels[1, i] = note
  end

  for i in range(1, NUM_COLS)
    tempo_button = styled(GtkButton(), "tempo-button")
    set_gtk_property!(tempo_button, :label, "1")
    set_gtk_property!(tempo_button, :xalign, 0.5)
    tablature[i, NUM_ROWS+1] = tempo_button

    function on_click_tempo(_)
      curr_text = get_gtk_property(tempo_button, :label, String)
      curr_tempo = parse(Int, curr_text)
      new_tempo = (curr_tempo % 4) + 1
      set_gtk_property!(tempo_button, :label, string(new_tempo))
    end
    signal_connect(on_click_tempo, tempo_button, "clicked")

  end

  function flip_wrap(_)
    global WRAP = !WRAP
    if WRAP
      set_gtk_property!(wrap_button, :label, "No wrap")
    else
      set_gtk_property!(wrap_button, :label, "Wrap")
    end
  end

  function on_export_button_press(_)
    output = ""
    save_file = save_dialog_native("Save file", GtkNullContainer(), ("*.txt",))
    for i in range(1, NUM_ROWS)
      for j in range(1, NUM_COLS)
        local entry = tablature[j, i]
        text = get_gtk_property(entry, :text, String)
        # text = (text == "") ?
        #        repeat("-", parse(Int, get_gtk_property(tablature[j, NUM_ROWS+1], :label, String))) :
        #        text * repeat("s", parse(Int, get_gtk_property(tablature[j, NUM_ROWS+1], :label, String)) - 1)
        text = (text == "") ? "-" : text
        # text = text * repeat("s", parse(Int, get_gtk_property(tablature[j, NUM_ROWS+1], :label, String)) - 1)
        output = string(output, text)
      end
      output = string(output, "\n")
    end
    for j in range(1, NUM_COLS)
      local entry = tablature[j, NUM_ROWS+1]
      text = get_gtk_property(entry, :label, String)
      output = string(output, text, " ")
    end
    write(save_file, output)
  end

  function on_back_button_press(_)
    create_main_window()
    Gtk.destroy(synth_win)
  end

  function on_clear_button_press(_)
    for i in range(1, NUM_ROWS)
      for j in range(1, NUM_COLS)
        entry = tablature[j, i]
        async_set(entry, "")
      end
    end
    for i in range(1, NUM_COLS)
      tempo_button = tablature[i, NUM_ROWS+1]
      set_gtk_property!(tempo_button, :label, "1")
    end
  end

  function on_play_button_press(_)
    output = ""
    for i in range(1, NUM_ROWS)
      for j in range(1, NUM_COLS)
        local entry = tablature[j, i]
        text = get_gtk_property(entry, :text, String)
        # text = (text == "") ?
        #        repeat("-", parse(Int, get_gtk_property(tablature[j, NUM_ROWS+1], :label, String))) :
        #        text * repeat("s", parse(Int, get_gtk_property(tablature[j, NUM_ROWS+1], :label, String)) - 1)
        text = (text == "") ? "-" : text
        # text = text * repeat("s", parse(Int, get_gtk_property(tablature[j, NUM_ROWS+1], :label, String)) - 1)
        output = string(output, text)
      end
      output = string(output, "\n")
    end
    for j in range(1, NUM_COLS)
      local entry = tablature[j, NUM_ROWS+1]
      text = get_gtk_property(entry, :label, String)
      output = string(output, text, " ")
    end

    write(string(now(), ".txt"), output)

    main_synthesizer_withDurations(string("history_", now(), ".txt"), reproduction_speed)
  end

  function on_import_button_press(_)
    file = open_dialog_native("Pick a file", GtkNullContainer(), ("*.txt",))
    println(file)
    if file != ""
      lines = readlines(file)
      line_length = length(lines[1])

      last_non_s_col = 1

      for i in range(1, line_length)
        for j in range(1, NUM_ROWS)
          char = lines[j][i]
          # if (char == "s")
          #   is_s_row = true
          #   print(i, " ", j, " ", last_non_s, "\n")
          #   tempo_button = tablature[last_non_s+1, NUM_ROWS+1]
          #   curr_tempo = get_gtk_property(tempo_button, :label, String)
          #   set_gtk_property!(tempo_button, :label, string(parse(Int, curr_tempo) + 1))
          #   break
          # else
          # if (char == 's')
          #   # print("is s\n")
          #   last_non_s_col = last_non_s_col - 1
          #   tempo_button = tablature[last_non_s_col+1, NUM_ROWS+1]
          #   curr_tempo = get_gtk_property(tempo_button, :label, String)
          #   set_gtk_property!(tempo_button, :label, string(parse(Int, curr_tempo) + 1))
          #   break
          # else
          if (char != "-")
            entry = tablature[last_non_s_col, j]
            async_set(entry, string(char))
          end
        end
        last_non_s_col = last_non_s_col + 1
      end
      counter = 1
      for i in range(1, stop=length(lines[NUM_ROWS+1]), step=2)
        tempo_button = tablature[counter, NUM_ROWS+1]
        counter = counter + 1
        set_gtk_property!(tempo_button, :label, string(lines[NUM_ROWS+1][i]))
      end
    end
  end

  function on_increase_tempo_button_press(_)
    curr_tempo = get_gtk_property(tempo_label, :label, String)
    new_tempo = round(min(4, parse(Float16, curr_tempo) + 0.1), digits=1)
    reproduction_speed = new_tempo
    set_gtk_property!(tempo_label, :label, string(new_tempo))
    if (reproduction_speed >= 4) # Max tempo
      return
    end
  end

  function on_decrease_tempo_button_press(_)
    curr_tempo = get_gtk_property(tempo_label, :label, String)
    new_tempo = round(max(0.1, parse(Float16, curr_tempo) - 0.1), digits=1)
    reproduction_speed = new_tempo
    set_gtk_property!(tempo_label, :label, string(new_tempo))
  end

  signal_connect(on_increase_tempo_button_press, increase_tempo_button, "clicked")
  signal_connect(on_decrease_tempo_button_press, decrease_tempo_button, "clicked")
  signal_connect(on_import_button_press, import_button, "clicked")
  signal_connect(flip_wrap, wrap_button, "clicked")
  signal_connect(on_export_button_press, export_button, "clicked")
  signal_connect(on_back_button_press, back_button, "clicked")
  signal_connect(on_clear_button_press, clear_button, "clicked")
  signal_connect(on_play_button_press, play_button, "clicked")

  synth_win = GtkWindow("", 400, 400)
  vbox = GtkBox(:v)
  header_box = GtkBox(:h)
  buttons_vbox = GtkBox(:v)
  entire_hbox = GtkBox(:h)
  tab_scroll = styled(GtkScrolledWindow(), "scroll-window")


  set_gtk_property!(tab_scroll, :hscrollbar_policy, Gtk.GtkPolicyType.ALWAYS)
  set_gtk_property!(tab_scroll, :vscrollbar_policy, Gtk.GtkPolicyType.NEVER)
  set_gtk_property!(tab_scroll, :min_content_width, 400)

  set_gtk_property!(tablature, :row_spacing, 5)

  push!(header_box, header)
  push!(header_box, back_button)
  push!(header_box, clear_button)
  push!(header_box, wrap_button)
  push!(header_box, decrease_tempo_button)
  push!(header_box, tempo_label)
  push!(header_box, increase_tempo_button)
  # push!(header_box, spinner)
  push!(vbox, header_box)
  push!(buttons_vbox, import_button)
  push!(buttons_vbox, export_button)
  push!(buttons_vbox, play_button)
  push!(entire_hbox, buttons_vbox)
  push!(tab_scroll, tablature)
  push!(entire_hbox, note_labels)
  push!(entire_hbox, tab_scroll)
  push!(entire_hbox, sidebar)
  push!(vbox, entire_hbox)
  push!(synth_win, vbox)
  showall(synth_win)
end

function create_transcriber_window()
  win = GtkWindow("Transcriber", 400, 400)
  vbox = GtkBox(:v)
  hbox = styled(GtkBox(:h), "header-box")
  header = styled(GtkLabel("Transcriber"), "header")
  back_button = styled(GtkButton("Back"), "export-button")

  # record_button = styled(GtkButton("Record"), "export-button")

  play_hbox = GtkBox(:h)
  # pause_button = styled(GtkButton("Pause"), "export-button")
  # save_button = styled(GtkButton("Save"), "export-button")
  import_button = styled(GtkButton("Import"), "export-button")

  recording = false

  # g = GtkGrid()
  # set_gtk_property!(g, :column_spacing, 10)
  # set_gtk_property!(g, :row_homogeneous, true)
  # set_gtk_property!(g, :column_homogeneous, true)

  S = 44100 # Sampling rate (samples/second)
  N = 1024 # Buffer length
  maxtime = 1000 # Maximum recording time in seconds (for demo)
  global recording = false # Flag
  nsample = 0 # Count number of samples recorded
  song = Float32[] # Initialize "song" as an empty array

  record_button = styled(GtkButton("Record"), "export-button")
  stop_button = styled(GtkButton("Stop"), "export-button")
  play_button = styled(GtkButton("Play"), "export-button")
  export_button = styled(GtkButton("Export"), "export-button")

  # new_record_button = make_button("Record", call_record, 1, "wr", "color:white; background:red;")
  # new_stop_button = make_button("Stop", call_stop, 2, "yb", "color:yellow; background:blue;")


  # Create buttons with callbacks, positions, and styles

  function on_back_button_press(_)
    create_main_window()
    Gtk.destroy(win)
  end

  # function on_record_button_press(_)
  #   recording = !recording
  #   if recording
  #     set_gtk_property!(record_button, :label, "Stop")
  #     push!(play_hbox, pause_button)
  #     push!(play_hbox, save_button)
  #     showall(win)
  #   else
  #     set_gtk_property!(record_button, :label, "Record")
  #     delete!(play_hbox, pause_button)
  #     delete!(play_hbox, save_button)
  #     showall(win)
  #   end
  # end

  function on_import_button_press(_)
    file = open_dialog_native("Pick a file", GtkNullContainer(), ("*.wav",))
    main_transcriber(file)
    println("Transcribed")
    # set_gtk_property!(import_button, :label, file)
  end

  # Initialize variables that are used throughout

  # Initialize variables that are used throughout



  # Callbacks

  function record_loop!(in_stream, buf)
    Niter = floor(Int, maxtime * S / N)
    println("\nRecording up to Niter=$Niter ($maxtime sec).")
    for iter in 1:Niter
      if !recording
        break
      end
      read!(in_stream, buf)
      append!(song, buf) # Append buffer to song
      nsample += N
      print("\riter=$iter/$Niter nsample=$nsample")
    end
  end

  function call_record(w)
    # Threads.@spawn begin
    global nsample = 0 # Count number of samples recorded
    global song = Float32[] # Initialize "song" as an empty array

    delete!(play_hbox, record_button)
    delete!(play_hbox, play_button)
    delete!(play_hbox, export_button)
    push!(play_hbox, stop_button)
    showall(win)
    # end
    Threads.@spawn begin
      in_stream = PortAudioStream(1, 0) # Default input device
      buf = read(in_stream, N) # Warm-up
      global recording = true
      global song = zeros(Float32, maxtime * S)
      @async record_loop!(in_stream, buf)
    end
  end

  function call_stop(w)
    global recording = false
    delete!(play_hbox, stop_button)
    push!(play_hbox, record_button)
    push!(play_hbox, play_button)
    push!(play_hbox, export_button)
    showall(win)
    # new_play_button = make_button("Play", call_play, 3, "wg", "color:white; background:green;")
    # new_export_button = make_button("Export", call_export, 4, "yb", "color:yellow; background:black;")
    # g[3, 1] = new_play_button
    # g[4, 1] = new_export_button

    sleep(0.1) # Ensure the async record loop finished
    duration = round(nsample / S, digits=2)
    flush(stdout)
    println("\nStopped recording at nsample=$nsample, duration $duration seconds.")
    global song = song[1:nsample] # Truncate song to the recorded duration
  end

  function call_play(w)
    # println("Playing recording.")
    @async sound(song, S) # Play the entire recording
  end

  function call_export(w)
    save_file = save_dialog_native("Save file", GtkNullContainer(), ("*.wav",))

    if (save_file != "")
      println("Exporting to $save_file")
      wavwrite(song, save_file, Fs=S)
    end
  end




  # g[1, 1] = new_record_button
  push!(play_hbox, record_button)
  # push!(play_hbox, stop_button)
  # push!(play_hbox, play_button)
  # push!(play_hbox, export_button)
  # g[3, 1] = new_play_button
  # g[4, 1] = new_export_button

  # push!(win, g) # Add grid to window
  # showall(win) # Display the window with all buttons

  signal_connect(call_record, record_button, "clicked")
  signal_connect(call_stop, stop_button, "clicked")
  signal_connect(call_play, play_button, "clicked")
  signal_connect(call_export, export_button, "clicked")

  signal_connect(on_import_button_press, import_button, "clicked")
  # signal_connect(on_record_button_press, record_button, "clicked")
  signal_connect(on_back_button_press, back_button, "clicked")

  push!(hbox, header)
  push!(hbox, back_button)
  push!(vbox, hbox)
  push!(vbox, import_button)
  # push!(play_hbox, record_button)
  push!(vbox, play_hbox)
  # push!(vbox, g)
  push!(win, vbox)
  showall(win)
end


create_main_window()
