# Spyglass
# ========
#
# This is Spyglass, a Rack web server that rides on Unix designed to be simple and teach
# others about Unix programming.
#
# It's namesake comes from the fact that when it boots up it's nothing more than a lone socket
# keeping a lookout for incoming connections. 
# 
# When a connection comes in it spins up a Master
# process which preforks some workers to actually handle http requests. If the Master process is
# left idle long enough it will shut itself (and it's workers) down and go back to just a lone
# listening socket, on the lookout for incoming connections.
#
# Components
# ==========
#
# * [Server](spyglass/server.html) gets the ball rolling. 
# The role of Server is pretty minimal. It opens the initial listening TCP socket,
# then passes that socket onto the Lookout. The Lookout will actually handle reading
# from the socket.
#
# * [Lookout](spyglass/lookout.html) keeps a watch and notifies others when a connection
# comes in. 
# The Lookout is a pretty 'dumb' object. All that it does is listen for incoming
# connections on the socket it's given. Once it receives a connection it does a fork(2) 
# and invokes a Master process. The Master process actually handles the connection.
#
# * [Master](spyglass/master.html) loads the application and babysits worker processes
# that actually talk to clients.
# The role of the Master class is to create and babysit worker processes
# that will actually handle web requests. The Master itself doesn't know
# anything about http, etc. it just knows how to manage processes.
#
# * [Worker](spyglass/worker.html) parses HTTP, calls the app, and writes back to the client.
require 'singleton'
require 'socket'
require 'stringio'
require 'redis'

require 'spyglass/configurator'
require 'spyglass/logging'
require 'spyglass/server'
require 'spyglass/lookout'
require 'spyglass/master'
require 'spyglass/dispatch_worker'
require 'spyglass/read_worker'
require 'spyglass/write_worker'
require 'spyglass/phoenix_patrol'
require 'spyglass/lockable'

module Spyglass
  Version = '0.1.1'
end
