module CoreWar
  
  class BattleGround

    attr_accessor :cells, :threads_to_add, :threads

    def initialize(commands, size = 100)
      @threads = [0]
      @threads_to_add = []
      @cells = inject_empty_cells(commands, size)
      @cells.map! { |cmd| Command.new(self, cmd) }
    end


    def each
      return to_enum(:each) unless block_given?
      while true
        @threads += @threads_to_add
        @threads_to_add.clear
        # p @threads
        @threads.each_with_index do |curr_cmd_ind, i|
          @current_thread_ind = i
          @cmd = @cells[curr_cmd_ind]
          raise StopIteration if @cmd.dat?
          yield @cmd.exec
          # p cmd
          @threads[i] = @cmd.jumped_to
        end
      end
    end

    def next_command
      i = @current_thread_ind
      if @threads.size != 1
        (next_cmd = threads[i+1]) ? next_cmd : threads.first
      else
        @cmd.jumped_to
      end

    end



    private
    
    #check that it injects additional empty operand if needed
    def inject_empty_cells(commands, size)
      (0...size).map do |i| 
        if commands.at(i).nil? 
          { index: i, name: "DAT", operands: [ { type: "#", value: 0, absolute_adr: nil},
                                               { type: "#", value: 0, absolute_adr: nil} ] }
        elsif commands[i][:operands][1].nil?
          commands[i][:operands][1] = { type: "#", value: 0, absolute_adr: nil}
          commands[i]
        else
          commands[i]
        end
      end
    end

    def filled_cells
      @cells.select { |c| !c.dat? }
    end


  end #Battleground
end #CoreWar