require "./redcode_file_parser.rb"
require "./battleground.rb"
require "./command.rb"
require "./tk_ui.rb"


module CoreWar
	class Game

		def initialize(parser = RedcodeFileParser.new)
			@views = []
      @parser = parser
      @parrsed_commands = []
      @bg = nil
		end

		def add_view(view)
			@views << view
		end

		def notify_views(meth, *args)
			@views.each{ |v| v.send(meth, *args) }
		end



    #Game Actions

		def load_file(file_name)
			@parrsed_commands = @parser.parse_file(file_name)
			@bg = BattleGround.new(@parrsed_commands)
			@iter = @bg.each
			notify_views(:file_loaded, @bg.cells)
		end

		def next_step
			executed_cell = @iter.next
      
      updated_cells = []
			updated_cells.push( (executed_cell.right_adress =~ /#/) ? executed_cell : executed_cell.go_right_adress)
			updated_cells.concat executed_cell.intermediate_cells.compact



			next_cell           = @bg.cells[executed_cell.jumped_to]
      next_expanded_cells = next_cell.expand_complex_adresses || []
      next_interm_cells   = next_cell.intermediate_cells.compact.map(&:index)

		  notify_views(:command_executed,
		               updated_cells,
		               executed_cell.jumped_to,
		               next_interm_cells,
		               next_expanded_cells)
		end

		def reset_cells
			@bg = BattleGround.new(@parrsed_commands)
			@iter = @bg.each
			notify_views(:reset_cells, @bg.cells)
		end



	end
end

game = CoreWar::Game.new
CoreWar::TkView.new(game)