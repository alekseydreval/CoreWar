  require "rspec"
  Dir[File.expand_path("../lib/*.rb")].each{ |f| require f }

  # Handle out of bound jumps (jmp +999)
  
  module CoreWar
    describe Command do

      before(:each) { @parser = RedcodeFileParser.new }

      context "handling out of bounds" do

        it "refers to cell with index 0 when [ADD 101, #13] is called for fieldset of 100 cells" do
          @parser.parse_line("ADD 101, #13")
          bg = BattleGround.new(@parser.commands)

          bg.cells[0].exec
          bg.cells[0].operands[1][:value].should == 26

        end

      end

      context "other commands" do

        it "executes MOV command [MOV #12, 14]" do
          @parser.parse_line("MOV #12, #14")
          bg = BattleGround.new(@parser.commands)

          bg.cells[0].exec
          bg.cells[0].operands[1][:value].should == 12
        end

        it "executes MOV command [MOV 0, 1]" do
          @parser.parse_line("MOV 0, 1")
          bg = BattleGround.new(@parser.commands)

          bg.cells[0].exec
          bg.cells[1].operands[0][:value].should == 0
          bg.cells[1].operands[1][:value].should == 1
          bg.cells[1].name.should == "MOV"
        end

        it "executes MOV command [MOV <-2, 1]" do
          @parser.parse_line("JMP #44")
          @parser.parse_line("DAT 0, -1")
          @parser.parse_line("MOV >-1, 1")
          bg = BattleGround.new(@parser.commands)

          bg.cells[2].exec
          bg.cells[3].name.should == "JMP"
          bg.cells[1].operands[1][:value].should == 0
        end

      end

      context "executing arithmetic operations" do

        it "executes ADD command [ADD #99, -1]" do
          @parser.parse_line("ADD #99, +1")
          @parser.parse_line("DAT #99, #11")
          bg = BattleGround.new(@parser.commands)

          bg.cells[0].exec
          bg.cells[1].operands[1][:value].should == 110
        end

        it "executes ADD command [ADD <-1, >+2]" do
          @parser.parse_line("ADD #99, +5")
          @parser.parse_line("ADD <-1, >1")
          @parser.parse_line("DAT 1, 1")
          @parser.parse_line("MOV 0, #19")
          @parser.parse_line("MOV #5, #5")

          bg = BattleGround.new(@parser.commands)
          bg.cells[1].exec
          bg.cells[0].operands[1][:value].should == 4
          bg.cells[2].operands[1][:value].should == 2
          bg.cells[3].operands[1][:value].should == 24
        end


        it "executes ADD command [ADD >2, >2]" do
          @parser.parse_line("ADD >2, >2")
          @parser.parse_line("ADD <-1, >1")
          @parser.parse_line("DAT 1, 1")
          @parser.parse_line("DAT 1, 44")

          bg = BattleGround.new(@parser.commands)
          bg.cells[0].exec 
          bg.cells[3].operands[1][:value].should == 88

        end

        it "executes ADD command [ADD >1, #13]" do
          @parser.parse_line("ADD >1, #13")
          @parser.parse_line("ADD <-1, >1")
          @parser.parse_line("DAT 1, 44")

          bg = BattleGround.new(@parser.commands)
          bg.cells[0].exec 
          bg.cells[0].operands[1][:value].should == 57
          bg.cells[1].operands[1][:value].should == 2
        end

        it "executes ADD command to self [ADD -10, #-2]" do
          @parser.parse_line('ADD #-10, #-2')
          bg = BattleGround.new(@parser.commands)

          bg.cells[0].exec
          bg.cells[0].operands[1][:value].should == -12
        end

        it "executes SUB command [SUB #5, -1]" do
          @parser.parse_line("DAT 0, #-2")
          @parser.parse_line("SUB #5, -1")
          bg = BattleGround.new(@parser.commands)

          bg.cells[1].exec
          bg.cells[0].operands[1][:value].should == -7
        end

        it "executes MUL command to self [MUL #-3, #10]" do
          @parser.parse_line("MUL #3, #-2")

          bg = BattleGround.new(@parser.commands)

          bg.cells[0].exec
          bg.cells[0].operands[1][:value].should == -6
        end

        it "executes MUL command [MUL -1, -1]" do
          @parser.parse_line('ADD  6, 7')
          @parser.parse_line("MUL -1, -1")
          bg = BattleGround.new(@parser.commands)

          bg.cells[1].exec
          bg.cells[0].operands[1][:value].should == 49
        end

        it "executes DIV command [DIV #2, #42]" do
          @parser.parse_line('ADD  6, 7')
          @parser.parse_line("DIV #-2, -1")
          bg = BattleGround.new(@parser.commands)

          bg.cells[1].exec
          bg.cells[0].operands[1][:value].should == -4
        end

        it "handles DIV by zero command!" do
          @parser.parse_line("DIV #-0, #5")
          bg = BattleGround.new(@parser.commands)

          expect { bg.cells[0].exec }.to raise_error
        end

        it "executes MOD command [MOD #3, #10]" do
          @parser.parse_line("MOD #3, #10")
          bg = BattleGround.new(@parser.commands)

          bg.cells[0].exec
          bg.cells[0].operands[1][:value].should == 1
        end

        it "executes MOD command with intermediate adressing(@)" do
          @parser.parse_line("ADD 0, +2")
          @parser.parse_line("MOD @-1, #40")
          @parser.parse_line("ADD 3, 9")

          bg = BattleGround.new(@parser.commands)
          
          bg.cells[1].exec
          bg.cells[1].operands[1][:value].should == 4
        end

        it "executes MOD command with post-increment adressing(>)" do
          @parser.parse_line("ADD 0, +2")
          @parser.parse_line("MOD #3, >-1")
          @parser.parse_line("ADD 3, 10")

          bg = BattleGround.new(@parser.commands)
          bg.cells[1].exec
          bg.cells[2].operands[1][:value].should == 1
          bg.cells[0].operands[1][:value].should == 3
        end

        it "executes MOD command with pre-decrement adressing(<)" do
          @parser.parse_line("ADD 0, +3")
          @parser.parse_line("MOD #3, <-1")
          @parser.parse_line("ADD 3, 10")

          bg = BattleGround.new(@parser.commands)
          bg.cells[0].operands[1][:value].should == 3
          bg.cells[1].exec
          bg.cells[0].operands[1][:value].should == 2
          bg.cells[2].operands[1][:value].should == 1
        end

      end

      context "iterating over commands and executing jumps" do

        context "error handling" do

          it "raises StopIteration when DAT command occured" do
            @parser.parse_line("DIV #2, #10")
            @parser.parse_line("JMP 19")

            bg = BattleGround.new(@parser.commands)

            iter = bg.to_enum(:each)
          
            iter.next
            iter.next
            expect { p iter.next }.to raise_error(StopIteration)
          end

          it "raises ZeroDivisionError when DIV by zero executed" do
            @parser.parse_line("DIV #0, #13")
            bg = BattleGround.new(@parser.commands)

            expect { bg.to_enum(:each).next }.to raise_error(ZeroDivisionError)
          end

        end

        it "jumps to certain adress" do
          @parser.parse_line("JMP +42")
          bg = BattleGround.new(@parser.commands)

          iter = bg.to_enum(:each)
          
          iter.next.jumped_to.should == 42  

        end

        it "jumps to certain adress (@)" do
          @parser.parse_line("ADD #3, 42")
          @parser.parse_line("SUB 0, 0")
          @parser.parse_line("JMP @-2")
          bg = BattleGround.new(@parser.commands)


          iter = bg.to_enum(:each)
          
          iter.next
          iter.next
          iter.next.jumped_to.should == 42  

          expect { iter.next }.to raise_error(StopIteration)

        end

        it "executes JMZ [JMZ +2, 0]" do
          @parser.parse_line("JMZ +2, #0")
          @parser.parse_line("SUB 0, 0")
          @parser.parse_line("ADD 1, 1")

          bg = BattleGround.new(@parser.commands)

          iter = bg.to_enum(:each)
          iter.next
          iter.peek.name.should == "ADD"

        end

        it "executes CMP and jumps i + 2 if operands equal " do
          @parser.parse_line("CMP #3, @2")
          @parser.parse_line("SUB 0, 1")
          @parser.parse_line("SUB 0, 1")
          @parser.parse_line("DAT 0, #3")
          bg = BattleGround.new(@parser.commands)

          iter = bg.to_enum(:each)

          iter.next.jumped_to.should == 2
        end

        it "executes CMP and jumps i + 1 if operands differ" do
         @parser.parse_line("CMP #3, <2")
          @parser.parse_line("SUB 0, 1")
          @parser.parse_line("SUB 0, #1")
          @parser.parse_line("DAT 0, #4")
          bg = BattleGround.new(@parser.commands)

          iter = bg.to_enum(:each)
        end

      end
    end
  end