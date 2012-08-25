http = require 'http'
fs = require 'fs'
path = require 'path'


class ServerFactory

  _ : undefined


  @defaultMimeType : 'text/html'

  @mimeTypes :
    '.js' : 'text/javascript'
    '.json' : 'application/json'
    '.css' : 'text/css'
    '.wave' : 'audio/wav'
    '.mp3' : 'audio/mp3'

  # Register a new server, start it and serve to the rest of the time.
  @initServer = (basePath = '.', port = 8888, onRequest) ->
    server = http.createServer (request, response) ->
      console.log 'request starting...'

      url = request.url

      # strip of any query string
      if url.indexOf('?') isnt -1
        url = url.substring(0, url.indexOf('?'))

      filePath = basePath + url

      # todo this is bullshit when basePath is flexible now
      if filePath is './'
        filePath = './index.html'

      extname = path.extname(filePath)
      contentType = if ServerFactory.mimeTypes[extname] then ServerFactory.mimeTypes[extname] else ServerFactory.defaultMimeType

      path.exists filePath, (exists) ->
        if exists
          fs.readFile filePath, (error, content) ->
            unless error
              response.writeHead 200, 'Content-Type' : contentType
              response.end content, 'utf-8'
              if onRequest then onRequest success : true, localeFilePath : filePath, requestUrl : request.url, contentType : contentType
            else
              response.writeHead 500
              response.end()
              if onRequest then onRequest success : false, localeFilePath : filePath, requestUrl : request.url, contentType : contentType
            return
        else
          response.writeHead 404
          response.end()
          if onRequest then onRequest success : false, localeFilePath : filePath, requestUrl : request.url, contentType : contentType
        return

    server = server.listen port

    console.log "Server running at http://127.0.0.1:#{port}/"

    return server


exports.ServerFactory = ServerFactory