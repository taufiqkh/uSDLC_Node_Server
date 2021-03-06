# Copyright (C) 2012,13 Paul Marrington (paul@marrington.net), see uSDLC2/GPL for license

# Create a HTTP server that processes requests based on the extension (being
# the characters after the final dot) - defaulting to 'html'. These drivers
# are modules in server/http/ext with a name that matches the extension. In 
# other words, html.coffee will be loaded to process index.html. The driver
# modules return a function that is called on each HTTP request and passed
# an exchange object consisting of

#   request: a node http.ServerRequest object
#       (http://nodejs.org/api/http.html#http_class_http_serverrequest)
#   response: a node http.ServerResponse object
#       (http://nodejs.org/api/http.html#http_class_http_serverresponse)
#   cookies: a lazy cookie loader and saver
#       (https://github.com/jed/cookies)
#   environment: an object common to all http conversations on this server.
#     port: The port number this server listens on
#     debug: If true errors close server with a stack dump
#     user: Default user if no-one has logged in
#   session: an object common to a single browser conversation set
#     user: Object containing details for a guest or logged in user
#   respond: method to call to send data back to the browser - chaining support
#   faye: pubsub server-side client. Set to false for no pubsub on server
#   config: Configuration file (<config>.config.coffee)

create_http_server = require 'boot/create-http-server'
create_faye_server = require 'boot/create-faye-server'
project_init = require 'boot/project-init'
respond = require 'http/respond'
os = require 'system'; fs = require 'file-system'

# process the command line
environment = process.environment = os.command_line
  base_dir: fs.base ''  # convenience path to server base directory
  config: 'base'        # used to load config settings (<name>.config.coffee)
  faye: true            # true to activate pubsub - set to faye.client
  port: 9009            # port used by both http and pubsub (as /faye)
  user: 'Guest'         # default user if one is not logged in

default_environment = ("#{name}=#{value}" for name, value of environment).sort()

respond.maximum_browser_cache_age = 1000 if environment.debug

# allow project to tweak settings before we commit to action
project_init.pre environment

# load an environment related config file
# command-line could have config=debug
# related file can be anywhere on the node requires paths + /config/
require("config/#{environment.config}")(environment)

# create a server ready to listen
environment.server = create_http_server environment
environment.faye = create_faye_server environment if environment.faye

# kick-off
environment.server.listen environment.port
# lastly we do more project level initialisation
project_init.post environment

console.log """

uSDLC2 running on http://localhost:#{environment.port}

usage: go server [name=value]...
    #{default_environment.join '\n    '}

"""
