
require 'tk'
require "./redcode_file_parser.rb"
require "./battleground.rb"
require "./command.rb"

module CoreWar
  class TkView

    BTN_WIDTH = 10

    CANVAS_WIDTH = 500

    CELLS_COUNT = 994



    def initialize
      pack_tk do
        @cells = [] #store reference to Battleground array
        @commands_list = init_commands_list
        @buttons = init_buttons
        @canvas = init_canvas
        @rectangles = fill_bg_with_cells
      end
    end

    def game_over
      Tk.messageBox "message" => "Game over"
    end

    def load_commands(parser = RedcodeFileParser.new)
      file = Tk::getOpenFile
      @raw_commands = parser.parse_file file
      reset_cells
    end

    def next_step
      cmd = @bg_iter.next 
      ind = @bg.next_command

        # cmd.jumped_to
      p cmd
      command_executed(cmd)
      position_changed(ind)
    end

    def start_iteration
      reset_cells
      @iteration_thread = Thread.new do
        while true
          sleep 0.3
          next_step rescue game_over
        end
      end
    end

    def stop_iteration
      Thread.kill @iteration_thread
      reset_cells
    end

    def reset_cells
      @bg = BattleGround.new(@raw_commands, CELLS_COUNT)
      @cells = @bg.cells
      @bg_iter = @bg.each
      @rectangles = fill_bg_with_cells

      display_loaded_commands
      prepare_iteration
      fill_loaded_cells
    end


    private

    def prepare_iteration
      position_changed(0)
    end


    def position_changed(ind)
      clean_last_position
      @commands_list.selection_set ind
      # @rectangles.eachh{ |r| r.fill = 'black' }
      @rectangles[ind].fill = 'red'
      @last_position = ind
    end

    def clean_last_position
      @raw_commands.size.times do |i|
        # next if @bg.threads.include?(i)
        @rectangles[i].fill = (@cells[i].dat? ? "black" : "yellow")
        @commands_list.selection_clear(i)
      end

    end

    def command_executed(cmd)
      return if %w(jmp jmz djn).include? cmd.name.upcase
      i = cmd.operands[1][:absolute_adr].to_i
      update_list_entry(@cells[i])
    end

    def update_list_entry(cell)
      @commands_list.delete(cell.index)
      @commands_list.insert cell.index, cmd_string(cell)
    end


    def pack_tk
      @master = init_master
      yield
      Tk.mainloop
    end


    def init_master
      TkRoot.new {
        title "CoreWar"
        minsize 500, 350
        maxsize 500, 350
      }
    end

    def init_buttons
      btnFrame = Tk::Tile::Frame.new(@master) {
        width 200
        height 200
        grid 'row'=> 1, 'column'=> 0, 'sticky'=>'nw', 'padx'=>10
        borderwidth 1
        relief "sunken"
      }

      buttons = Hash.new

      this = self

      buttons[:load_file] = TkButton.new(btnFrame){
        grid('row'=>0, 'column'=>0, 'sticky'=>'w')
        text "Load file"
        width BTN_WIDTH
        command -> { this.load_commands; buttons[:next].state = "normal"; buttons[:iterate_or_pause].state = "normal"; buttons[:restart].state = "normal" }
      }
      
      start = nil
      stop  = -> do 
        this.stop_iteration
        buttons[:iterate_or_pause].command = start
        buttons[:iterate_or_pause].text = "Start iteration"
        buttons[:load_file].state = "normal"
        buttons[:next].state = "normal"
        buttons[:restart].state = "normal"
      end

      start = -> do 
        this.start_iteration
        buttons[:iterate_or_pause].command = stop 
        buttons[:iterate_or_pause].text = "Stop iteration"
        buttons[:load_file].state = "disabled"
        buttons[:next].state = "disabled"
        buttons[:restart].state = "disabled"
      end

      buttons[:iterate_or_pause] = TkButton.new(btnFrame){
        grid('row'=>1, 'column'=>0, 'sticky'=>'w')
        text "Start iteration"
        width BTN_WIDTH
        command start
        state "disabled"
      }

      buttons[:next] = TkButton.new(btnFrame){
        grid('row'=>2, 'column'=>0, 'sticky'=>'w')
        text "Next step"
        width BTN_WIDTH
        command -> { this.next_step rescue this.game_over}
        state "disabled"
      }

      buttons[:restart] = TkButton.new(btnFrame){
        grid('row'=>3, 'column'=>0, 'sticky'=>'w')
        text "Restart"
        width BTN_WIDTH
        command -> { this.reset_cells }
        state "disabled"
      }

      buttons
    end

    def init_commands_list

      list = TkListbox.new(@master) {
        grid("row"=>1, "column"=>1)
        width 33
        height 8
        font TkFont.new("family" => 'Courier', 
                        "size" => 12)
      }

      scroll = TkScrollbar.new {
        command proc{|*args|  list.yview(*args)  }
        grid("row"=>1, "column"=>2, "sticky"=>"ns")
      }

      list.yscrollcommand(proc { |*args|
        scroll.set(*args)
      })

      scroll.command(proc { |*args|
        list.yview(*args)
      }) 

      list

    end

    def init_canvas
      TkCanvas.new(@master) { 
        width CANVAS_WIDTH
        grid 'row'=>0, 'column'=>0, 'columnspan'=>3,'sticky'=>"ew"
        height 150
      }
    end

    def display_loaded_commands
      @commands_list.clear
      format_commands do |cmd|
        @commands_list.insert 'end', cmd
      end
    end

    def cmd_string(cmd)
      sprintf(" %-10s %1s%-13d %1s%d",
              cmd.name,
              cmd.operands[0][:type],
              cmd.operands[0][:value],
              cmd.operands[1][:type],
              cmd.operands[1][:value])
    end

    def format_commands
      @cells.each do |cmd|
        yield cmd_string(cmd)
      end
    end


    def fill_bg_with_cells(cells = Array.new(CELLS_COUNT), padding = 0.3, size = 7)
      x = y = 0
      next_x = next_y = x +size
      
      cells.map do |_|  
        if next_x > CANVAS_WIDTH
          x = 0
          next_x = x + size
          y = next_y
          next_y += size
        end

        rect = TkcRectangle.new(@canvas, x, y, next_x, next_y, 'outline' => 'gray', 'fill' => 'black')
        x = next_x + (padding/2)
        next_x += size
        rect
      end
    end

    def fill_loaded_cells
      @rectangles[10].fill = "yellow"
      @rectangles.zip(@cells).each do |rect, cell|
        next if cell.dat? || rect.fill == "red"
        rect.fill = "yellow"
      end
    end

  end
end

CoreWar::TkView.new