require 'multiball'
require 'mocha'

describe Multiball do

  before(:each) do #can't use rspec stub inside here and have it work?
    Multiball.expects(:get_server).returns("server").times(2)
  end
  
  it "initializes the server list once" do
  	Multiball.set_config!({ :one => {:config=>{}}, :two => {:config=>{}}})
	ball1 = Multiball.new
    ball2 = Multiball.new
    ball3 = Multiball.new
    Multiball.servers.size.should eq(2)
  end

  it "can have a an affinity" do
  	Multiball.should respond_to(:affinity) 
  	Multiball.should respond_to(:preferred_servers)
  end

  it "should return a preferred_server if localhost" do
  	Multiball.prefer?(:localhost,{}).should == true
  	Multiball.set_config!({ :localhost => {:config=>{}}, :two => {:config=>{}}})
  	Multiball.preferred_servers.size.should eq(1)
  	Multiball.affinity.should == true
  end

end
