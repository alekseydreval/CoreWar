
require 'tk'

module CoreWar
  class TkView

    BTN_WIDTH = 10

    CANVAS_WIDTH = 500

    CELLS_COUNT = 994

    attr_reader :game



    def initialize(game)
      @game = game #acts as controller
      @game.add_view self

      pack_tk do 
        @commands_list = init_commands_list
        @buttons = init_buttons
        @canvas = init_canvas
        @rectangles = init_default_cells
      end

    end



    #These methods are called by Game controller as rendered response
    #
    def file_loaded(commands)
      @commands_list.delete 0, @commands_list.size
      fill_loaded_cells(commands)

      format_commands(commands) { |cmd| @commands_list.insert 'end', cmd }
      highlight_next_command(0, [])
    end


    def command_executed(updated_cells, next_ind, next_interm_indexes, next_expanded_indexes)
      update_list_entry(updated_cells)
      highlight_next_command(next_ind, next_expanded_indexes, next_interm_indexes)
    end


    # Triggers controller's method
    def load_commands
      file = Tk::getOpenFile 
      @game.load_file(file) rescue return
    end

    def next_step
      begin
        game.next_step 
      rescue StopIteration
        Tk.messageBox "message" => "Game over"
        stop_iteration 
      rescue ZeroDivisionError
        Tk.messageBox "message" => "Division by zero!"
        stop_iteration 
      rescue
        Tk.messageBox "message" => "Operand points outside the bound!"
        stop_iteration 
      end
    end

    def start_iteration
      game.reset_cells
      @iteration_thread = Thread.new do
        while true
          sleep 0.3
          next_step
        end
      end
    end

    def stop_iteration
      game.reset_cells
      @stop.call
      Thread.kill @iteration_thread if @iteration_thread
    end

    def reset_cells(cells)

      @commands_list.size.times { |i| @commands_list.itemconfigure i, "bg"=>"white" }
      
      @restarted = true

      fill_loaded_cells(cells)
      highlight_next_command(0, [])
    end


    private

    def highlight_next_command(ind, expanded_indexes = [], intermediate_indexes = [])

      if @prev_ind
        @rectangles[@prev_ind].fill = 'yellow' unless @restarted
        @restarted = false
        @commands_list.itemconfigure @prev_ind, "bg" => "white"
        @prev_interm_cells.concat(@prev_expanded_cells).each do |i|
          @commands_list.itemconfigure i, "bg" => "white" 
        end
      end

      intermediate_indexes.each { |i| @commands_list.itemconfigure i, "bg" => "gray"}

      expanded_indexes.each { |i| @commands_list.itemconfigure i, "bg" => "green" }


      @commands_list.itemconfigure(ind, "bg" => "red")
      @rectangles[ind].fill = "red"

      @prev_ind = ind
      @prev_interm_cells = intermediate_indexes
      @prev_expanded_cells = expanded_indexes

    end


    def update_list_entry(cells)
      cells.each do |cell|
        @commands_list.delete(cell.index)
        @commands_list.insert cell.index, format_cmd(cell)
      end
    end


    # GUI initialization
    #
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
      game = @game

      buttons[:load_file] = TkButton.new(btnFrame){
        grid('row'=>0, 'column'=>0, 'sticky'=>'w')
        text "Load file"
        width BTN_WIDTH
        command -> { this.load_commands; buttons[:next].state = "normal"; buttons[:iterate_or_pause].state = "normal"; buttons[:restart].state = "normal" }
      }
      
      start = nil
      @stop  = -> do 
        buttons[:iterate_or_pause].command = start
        buttons[:iterate_or_pause].text = "Start iteration"
        buttons[:load_file].state = "normal"
        buttons[:next].state = "normal"
        buttons[:restart].state = "normal"
      end

      start = -> do 
        this.start_iteration
        buttons[:iterate_or_pause].command = @stop 
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
        command -> { this.next_step }
        state "disabled"
      }

      buttons[:restart] = TkButton.new(btnFrame){
        grid('row'=>3, 'column'=>0, 'sticky'=>'w')
        text "Restart"
        width BTN_WIDTH
        command -> { game.reset_cells }
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

   

    #Helpers
    #

    def init_default_cells(cells = Array.new(CELLS_COUNT), padding = 0.3, size = 7)
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

    def fill_loaded_cells(cells)
      @rectangles.zip(cells).each do |rect, cell|
        break if cell.nil?
        if cell.dat?
          rect.fill = "black"
        else
          rect.fill = "yellow"
        end
      end
    end

    def format_cmd(cmd)
      sprintf(" %-10s %1s%-13d %1s%d",
                      cmd.name,
                      cmd.operands[0][:type],
                      cmd.operands[0][:value],
                      cmd.operands[1][:type],
                      cmd.operands[1][:value])
    end


    def format_commands(cmds)
      cmds.each do |cmd|
        yield format_cmd(cmd)
      end
    end

  end
end

