module CoreWar
  
  class RedcodeFileParser
    
    ALLOWED_COMMANDS = %w(MOV ADD SUB MUL DIV MOD JMP JMZ JMG DJZ CMP SEQ SNE DAT)

    ALLOWED_ADRESSES_TYPES = %w($ # < > @)

    attr_reader :commands_list

    def initialize(opts = {})
      @commands_list = []
    end

    def parse_file(file, dir = File.expand_path(File.dirname(__FILE__)))
      File.open(File.join(dir, file)).each_line { |line| parse_line(line) }
      finish_parsing
    end

    def parse_line(command_line)
      splitted_line = command_line.split(" ")
      operands = []
      cmd_name = splitted_line[0]

      if splitted_line.size == 2
        if (ops = splitted_line[1].split(',')).size == 2 #[ADD 3,9]
          operands.concat ops
        elsif !splitted_line[1][','] #skip cases like: [MOV +3,]
          operands << splitted_line[1] #[JMP +3]
        else
         raise MaliciousFile
       end
      elsif splitted_line.size == 4 #[JMZ @-1 , >+2]
        operands << splitted_line[1] << splitted_line[4] 
      elsif splitted_line.size == 3 && (ops = splitted_line[1..2].join)[','] #[SUB <2, -42] or [SUB <2 ,-42]
        operands.concat ops.split(',')
      else
        raise MaliciousFile
      end

      raise MaliciousFile if !ALLOWED_COMMANDS.include?(cmd_name) || !operands_correct?(operands)

      operands.map! do |op|
        mtch = op.match(/(?<type>[$#\@<>])*(?<value>.+)/)
        { type: mtch[:type].to_s, value: mtch[:value].to_i, absolute_adr: nil }
      end  
      
      cmd = { index: @commands_list.length, name: cmd_name, operands: operands }
      @commands_list << cmd
      cmd

    end

    def finish_parsing
      @commands_list
    end


    
    private

    def operands_correct?(op)
      [op].flatten.all? do |o|
        if ALLOWED_ADRESSES_TYPES.include? o[0]
          o[1..-1].to_i.to_s == o[1..-1] || o[1..-1].to_i.to_s == o[2..-1]
        else
          o.to_i.to_s == o || o.to_i.to_s == o[1..-1]
        end
      end
    end

  end  
end