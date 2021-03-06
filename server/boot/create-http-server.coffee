# Copyright (C) 2013 Paul Marrington (paul@marrington.net), see uSDLC2/GPL for license
http = require 'http'; url = require 'url'
Cookies = require 'cookies'; driver = require 'http/driver'
respond = require 'http/respond'; fs = require 'file-system'

module.exports = (environment) ->
  return environment.server = http.createServer (request, response) ->
    console.log request.url
    request.pause()
    request.url = url.parse request.url, true
    fs.find request.url.pathname, (filename) ->
      try
        request.filename = filename
        
        cookies = new Cookies(request, response)
        user = environment.user if not (user = cookies.get 'usdlc_session_id')
        session = {user}

        # some drivers cannot set mime type. For these we put it in the query string
        # as txt or text/plain.
        if request.url.query.mime_type
          respond.set_mime_type request.url.query.mime_type, response

        # all the set up is done, process the request based on a driver for file type
        driver(request.filename)({
          request, response, environment, session, cookies, reply: respond.static})
      catch error
        console.log error.stack ? error
        response.end(error.toString())
