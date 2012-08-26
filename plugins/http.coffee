http = require 'http'
fs = require 'fs'
path = require 'path'
OptParse = require 'optparse'
{Plugin} = require '../lib/plugin'

### >>> Configuration Option Parser ###
Switches = [
  [ '-httppln', '--http-public-localhost-name VALUE', 'Define the hostname (or addr) of this machine to allow access to the files. Default is "localhost".']
  [ '-httpplp', '--http-public-localhost-port VALUE', 'Define the port of this machine to allow access to the files. Default is "8888".']
]

Options =
  publicLocalhostName : 'localhost'
  publicLocalhostPort : 8888

Parser = new OptParse.OptionParser Switches
Parser.banner = "Usage of Plugin Http:"

Parser.on "http-public-localhost-name", (opt, value) ->
  Options.publicLocalhostName = value

Parser.on "http-public-localhost-port", (opt, value) ->
  Options.publicLocalhostPort = value
### << Configuration Option Parser ###


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
  initServer : (basePath = '.', port = 8888) ->
    server = http.createServer (request, response) =>
      url = request.url

      # strip of any query string
      if url.indexOf('?') isnt -1
        url = url.substring(0, url.indexOf('?'))

      filePath = basePath + url

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

    server = server.listen port

    return server

  getPublicPath : (localePath) ->
    # TODO protocol scheme
    "http://#{Options.publicLocalhostName}:#{Options.publicLocalhostPort}/#{localePath}"


###
  Exports & Plugin Interface
###

exports.help = () ->
  console.log Parser.toString()

exports.init = (bot, argv, options) ->
  if options
    Plugin.copyOptions options, Options
  else
    Parser.parse argv

  plugin = new Http bot
  plugin.initServer '.', Options.publicLocalhostPort
  return plugin