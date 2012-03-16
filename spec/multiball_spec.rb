require 'multiball'
require 'mocha'
require 'lawger'
describe Multiball do

  it "should support drivers as part of the config" do
    Multiball.should respond_to(:driver)
    Multiball.should respond_to(:driver=)
    Multiball.driver=Multiball::HashDriver
  end

  it "initializes the server list once" do

    Multiball.set_config!({ :one => {:config=>{}}, :two => {:config=>{}}})
    ball1 = Multiball::Ball.new
    ball2 = Multiball::Ball.new
    ball3 = Multiball::Ball.new
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

  #TODO: Reorg specs to not conflate
  it "should proxy commands" do
    Multiball.driver=Multiball::HashDriver
    Multiball.set_config!({ :localhost => {:config=>{}}, :two => {:config=>{}}})

    #Multiball.unstub(:get_server)
    ball1 = Multiball::Ball.new
    #   ball1.should respond_to(:set)
    ball1.set "foo", "bar"
    ball1.get("foo").should eq("bar")
    ball1.collect{|k,v| [k,v] }.flatten.should eq(%w[foo bar])
  end

  it "should multicast" do
    Multiball.driver=Multiball::HashDriver
    Multiball.set_config!({ :one => {:config=>{}}, :two => {:config=>{}}})
    ball1 = Multiball::Ball.new
    ball1["foo"]="bar"
    ball1.merge!({'bar' => 'foo'})
    ball1.hashie.should eq({"foo" => "bar", "bar" => "foo"})
    Multiball.servers.each do |key,server|
      Hash[server.collect{|k,v| [k,v] }].should eq({"foo" => "bar", "bar" => "foo"})
    end
  end

  it "should purgatory from an unreachable server" do
    Multiball.driver=Multiball::HashDriver
    Multiball.set_config!({ :one => {:config=>{}}, :two => {:config=>{ :go_bad => true }}})
    ball1 = Multiball::Ball.new
    ball1.merge!({"foo" => "bar", "bar" => "foo", "utterly" => "foobar"})
    ball1.reject!{|k,v| k == "utterly" }
    Multiball.servers.each do |key,server|
       Hash[Multiball::Ball.new.collect{|k,v| [k,v] }].should eq({"foo" => "bar", "bar" => "foo"})
    end
  end

  it "should have a retrieve mechanism" do
    Multiball.should respond_to(:get)
  end

end
