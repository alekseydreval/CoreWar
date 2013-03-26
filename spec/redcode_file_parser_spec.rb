require "rspec"
Dir[File.expand_path("../lib/*.rb")].each{ |f| require f }

describe CoreWar::RedcodeFileParser do 

  before(:each){ @parser = CoreWar::RedcodeFileParser.new(:size => 100) }
  

  context "parse line" do

    it "raises a error if command is unknown" do
      expect { @parser.parse_line("FOO #3, 0") }.to raise_error(CoreWar::MaliciousFile)
    end

    it "raises a error if operands have wrong format" do
      expect { @parser.parse_line("MOV #nowhere, 99") }.to raise_error(CoreWar::MaliciousFile)
      expect { @parser.parse_line("ADD $-infinity, +1") }.to raise_error(CoreWar::MaliciousFile)
      expect { @parser.parse_line("ADD whatever, whatever") }.to raise_error(CoreWar::MaliciousFile)
    end

    it "raises a error if no second operand follows comma" do
      expect { @parser.parse_line("SUB #-1, ")}.to raise_error(CoreWar::MaliciousFile)
    end

    it "raises a error if no comma breaks up two operands" do
      expect { @parser.parse_line("SUB 0 0")}.to raise_error(CoreWar::MaliciousFile)
    end

    it "passes validation" do
      expect { @parser.parse_line("MOV +1, -3") }.to_not raise_error 
      expect { @parser.parse_line("JMP 0") }.to_not raise_error
      expect { @parser.parse_line("CMP >-3, <+4") }.to_not raise_error
      expect { @parser.parse_line("CMP @-3,#4") }.to_not raise_error
      expect { @parser.parse_line("ADD -3,       +53") }.to_not raise_error
      expect { @parser.parse_line("  ADD      -3,       +53") }.to_not raise_error
    end

  end

  context "parse file" do

    it "successfully parses file, returning a Hash with appropriate keys/values" do
      CoreWar::RedcodeFileParser.new.parse_file('blob.redcode').each do |cmd| 
        cmd.should be_an_instance_of(Hash)
        cmd[:index].should be_an_instance_of(Fixnum)
        cmd[:name].should be_an_instance_of(String)
        cmd[:operands].should be_an_instance_of(Array)
        cmd[:operands].length.should be <= 2
      end
    end

    it "raises a error if file is not found" do
      expect { CoreWar::RedcodeFileParser.new.parse_file('unexisted_file.redcode') }.to raise_error(Errno::ENOENT)
    end

    it "raises a error if file content is invalid" do
      expect { CoreWar::RedcodeFileParser.new.parse_file('blob_invalid.redcode') }.to raise_error(CoreWar::MaliciousFile)
    end

  end

end