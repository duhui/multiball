require 'socket'

100000.times do |i|
  begin
  	p 'open!'
    TCPSocket.open('localhost', 4222) do |c|
      read,write=IO.select([], [c], [], 5);
      write[0].puts Marshal.dump([:set, "fubar!#{i}", "fubar!!!!"]);
      read,write=IO.select([c], [], [], 5);
      puts "#{Marshal.load(read[0].recv(10000))}"
    end
    TCPSocket.open('localhost', 4222) do |c|
      read,write=IO.select([], [c], [], 5);
      write[0].puts Marshal.dump([:get, "fubar!#{i}"]);
      read,write=IO.select([c], [], [], 5);
      puts "#{Marshal.load(read[0].recv(10000))}"
    end
  rescue
  	p 'looks like a timeout.'
  end
end
