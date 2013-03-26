module CoreWar
  
  class BattleGround

    attr_accessor :cells

    def initialize(commands, size = 100)
      @cells = inject_empty_cells(commands, size)
      @cells.map! { |cmd| Command.new(self, cmd) }
    end


    def each
      i = 0
      until (cmd = @cells[i]).dat? do
        yield cmd.exec
        i = cmd.jumped_to || i + 1
      end
      yield (raise StopIteration, cmd.inspect)
    end



    private

    def inject_empty_cells(commands, size)
      (0...size).map do |i| 
        if commands.at(i).nil? 
          { index: i, name: "DAT", operands: [ { type: "#", value: 0, absolute_adr: nil},
                                               { type: "#", value: 0, absolute_adr: nil} ] }
        else
          commands[i]
        end
      end
    end

    # def update_view
    #   @cells.each{ |cell| print_cell cell }
    # end

    # def print_cell(cell)
    # end

    def filled_cells
      @cells.select { |c| !c.nil? }
    end


  end #Battleground
end #CoreWar