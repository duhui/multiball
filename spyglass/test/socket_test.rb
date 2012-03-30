require 'socket'

10000.times do |i|
  begin
  	sleep 0.1
  	TCPSocket.open('localhost', 4222) do |c|
      read,write=IO.select([], [c], [], 5);
      write[0].puts Marshal.dump([:set, "fubar!#{i}", "fubar!!!!"]);
      read,write=IO.select([c], [], [], 5);
      puts "#{Marshal.load(read[0].recv(10000))}"
      c.close
    end
    sleep 0.1
  	TCPSocket.open('localhost', 4222) do |c|
      read,write=IO.select([], [c], [], 5);
      write[0].puts Marshal.dump([:get, "fubar!#{i}"]);
      read,write=IO.select([c], [], [], 5);
      puts "#{Marshal.load(read[0].recv(10000))}"
      c.close
    end
  rescue
  	p 'looks like a problem!'
  end
end
