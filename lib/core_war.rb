require 'active_support/all'
require "ostruct"

require "redcode_file_parser.rb"
require "battleground.rb"


module CoreWar

  class MaliciousFile < Exception; end;
  
  def self.init(redcode_file, opts = {})
    commands     = RedcodeFileParser.new.parse_file(redcode_file, opts[:dir])
    battleground = BattleGround.new(commands, opts.slice(:speed, :cells_count))
    battleground.start_iteration
  end

end

# CoreWar.init('blob.redcode')