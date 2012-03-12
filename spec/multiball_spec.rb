require 'multiball'

describe Multiball do

  before(:all) do
    Multiball.set_config [{},{}]
  end

  it "initializes the server list once" do
    server = double("server")
    Multiball.class.stub(:get_server) { server }
    ball1 = Multiball.new
    ball2 = Multiball.new
    ball3 = Multiball.new
    Multiball.servers.size.should eq(2)
  end
end
