http = require 'http'
fs = require 'fs'
path = require 'path'
{Plugin} = require '../lib/plugin'


config =
  options :
    'base-path' :
      default : '.'
      alias : 'bp'
      value : true
      description : 'Base path'
      parse : (opt, value) -> value
    'public-localhost-name' :
      default : 'localhost'
      alias : 'pln'
      value : true
      description : 'Define the hostname (or addr) of this machine to allow access to the files. Default is "localhost".'
      parse : (opt, value) -> value
    'public-localhost-port' :
      default : 8888
      alias : 'plp'
      value : true
      description : 'Define the port of this machine to allow access to the files. Default is "8888".'
      parse : (opt, value) -> value


class Mimetypes
  @data :
    '.js' : 'text/javascript'
    '.json' : 'application/json'
    '.css' : 'text/css'
    '.wave' : 'audio/wav'
    '.mp3' : 'audio/mp3'


class Http extends Plugin
  _ : undefined

  defaultMimeType : 'text/html'

  getName : -> 'Http'

  getEventNames : -> ['http.request']

  afterRequest : (success, localFilePath, requestUrl, contentType) ->
    @bot.getEmitter().emit 'http.request', success, localFilePath, requestUrl, contentType

  # Register a new server, start it and serve to the rest of the time.
  initServer : () ->
    server = http.createServer (request, response) =>
      url = request.url
      @log 'request', url

      # strip of any query string
      if url.indexOf('?') isnt -1
        url = url.substring(0, url.indexOf('?'))

      filePath = @options['base-path'] + url

      # todo this is bullshit when basePath is flexible now
      if filePath is './'
        filePath = './index.html'

      extname = path.extname(filePath)
      contentType = if Mimetypes.data[extname] then Mimetypes.data[extname] else @defaultMimeType

      path.exists filePath, (exists) =>
        if exists
          fs.readFile filePath, (error, content) =>
            unless error
              response.writeHead 200, 'Content-Type' : contentType
              response.end content, 'utf-8'
              @afterRequest true, filePath, request.url, contentType
            else
              response.writeHead 500
              response.end()
              @afterRequest false, filePath, request.url, contentType
            return
        else
          response.writeHead 404
          response.end()
          @afterRequest false, filePath, request.url, contentType
        return

    server = server.listen @options['public-localhost-port']
    @log 'started', @getPublicPath ''

    return server

  getPublicPath : (localePath) ->
    # TODO protocol scheme
    "http://#{@options['public-localhost-name']}:#{@options['public-localhost-port']}/#{localePath}"


### Exports & Plugin Interface ###

exports.config = config

exports.init = (bot, pluginId) ->
  new Http bot, pluginId

exports.run = (plugin) ->
  plugin.initServer()