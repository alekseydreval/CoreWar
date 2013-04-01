module CoreWar
  class RedcodeFileParser
    
    ALLOWED_COMMANDS = %w(MOV ADD SUB MUL DIV MOD JMP JMZ JMG DJZ CMP SEQ SNE DAT SPL DJN ORG)

    ALLOWED_ADRESSES_TYPES = %w($ # < > @)

    attr_reader :commands

    

    def initialize(opts = {})
      @commands = []
    end

    def parse_file(file)
      File.open(file).each_line { |line| parse_line(line) }
      @commands
    end

    def parse_line(raw_line)
      validated_command(raw_line) do |cmd_name, operands| 
        cmd = build_command(cmd_name, operands)
        @commands << cmd
        cmd
      end
    end



    private

    def build_command(cmd_name, operands )
      command = {}
      command[:index] = @commands.length
      command[:name]  = cmd_name
      command[:operands] = []

      operands.each do |op|
        mtch = op.match(/(?<type>[$#\@<>])*(?<value>.+)/)
        command[:operands] << { type: "#{mtch[:type] || '$'}", value: mtch[:value].to_i, absolute_adr: nil }
      end
      command
    end
      



    def validated_command(command_line)
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

      yield(cmd_name, operands)
    end


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