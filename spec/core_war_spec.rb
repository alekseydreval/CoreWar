require "rspec"
Dir[File.expand_path("../lib/*.rb")].each{ |f| require f }


describe CoreWar do

  it "initializes game if .redcode file specified" do
    expect { CoreWar.init('blob.redcode') }.not_to raise_error
  end

  it "raises error if file was not found" do
    expect { CoreWar.init('blob_invalid.redcode') }.to raise_error(CoreWar::MaliciousFile)
  end


end
