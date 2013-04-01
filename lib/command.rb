module CoreWar
  class Command

    attr_accessor :index, :name, :operands, :left_adress, :right_adress, :go_left_operand, :go_right_operand, :jumped_to

    def initialize(battleground, cell)
      @threads_to_add = battleground.threads_to_add
      @cells = battleground.cells
      @index = cell[:index]
      @name  = cell[:name]
      @operands = cell[:operands]
      @jumped_to = @index + 1
    end

    def exec
      @operands = expand_adresses(@operands)
      check_for_decrement
      send @name.downcase.to_sym
      check_for_increment
      self
    end

    def dat?
      @name.downcase == "dat"
    end




    def left_adress
      @operands[0][:absolute_adr]
    end

    def right_adress
      @operands[1][:absolute_adr]
    end

    def go_left_adress
      @cells[left_adress]
    end

    def go_right_adress
      @cells[right_adress]
    end

    def intermediate_cells
      @operands.each_index.map do |ind| 
        if [">", "<", "@"].include? @operands[ind][:type] 
          @cells[@index + @operands[ind][:value]]
        end
      end
    end



    private
    
    #calculates absolute adressing for operands with types @, >, <
    #NOTE that no increment/decrement goes here
    def expand_adresses(operands)
      operands.map do |op|
        op[:absolute_adr] = 
          if op[:type] == "#"
              "##{op[:value]}"
          else
            intermediate_cell = @cells[@index + op[:value]]
            
            if ["@", ">", "<"].include? op[:type]
              intermediate_cell.operands[1][:value] + intermediate_cell.index
            else
              @index + op[:value] 
            end
          end
        op
      end
    end

    def check_for_decrement
      intermediate_cells.each_with_index do |c, i| 
        next if c.nil?
         if @operands[i][:type] == "<"  
           c.operands[1][:value] -= 1
           @operands[i][:absolute_adr] -= 1 #fix absolute adress so that the command executes according to right adresses
         end
      end
    end

    def check_for_increment
      intermediate_cells.each_with_index do |c, i| 
        next if c.nil?
        c.operands[1][:value] += 1 if @operands[i][:type] == ">"  
        p c
      end
    end

    #commands helpers
    def destination
      (right_adress =~ /#/) ? operands[1] : go_right_adress.operands[1]
    end

    #check if self-referencial
    def source_data
      (left_adress =~ /#/) ? operands[0][:value] : go_left_adress.operands[1][:value]
    end

    
    def spl
      @threads_to_add << go_left_adress.index
    end

    def mov
      if left_adress =~ /#/
        destination[:value] = source_data
      else
        go_right_adress.name     = go_left_adress.name
        go_right_adress.operands = go_left_adress.operands
      end
    end

    

    def add
      destination[:value] += source_data
    end

    def sub
      destination[:value] -= source_data
    end

    def mul
      destination[:value] *= source_data
    end

    def div
      destination[:value] /= source_data
    end

    def mod
      destination[:value] %= source_data
    end



    def jmp
      return if left_adress =~ /#/  #JMP operand can't be a constant
      @jumped_to = left_adress
    end
    
    def jmz #JMP A if B = 0
      return if left_adress =~ /#/
      # p source_data
      @jumped_to = left_adress if (destination[:value] == 0)
    end

    def jmn
      return if left_adress =~ /#/
      @jumped_to = left_adress if (destination[:value] != 0)
    end



    def djn
      return if left_adress =~ /#/
      @jumped_to = right_adress if destination[:value] != 0
    end


    def cmp
      @jumped_to = @index + 2 if destination[:value] == source_data
    end

    def org
      @jumped_to = jmp + 1
    end
    
    #... 
    #... 



    def to_s
      "\n[#{@index}] #{name.upcase} #{@operands}"
    end

  end
end