{EventEmitter2} = require 'eventemitter2'


class Logger

  @enabled : false

  @log : (messages...) ->
    if Logger.enabled
      console.log messages.join ', '


class Bot

  loggingEnabled : false

  constructor : (@emitter, @options)->
    @init()

  isLoggingEnabled : -> @loggingEnabled

  setLoggingEnabled : (@loggingEnabled) ->
    Logger.enabled = @loggingEnabled

  getEmitter : -> @emitter

  plugins : null

  loadPlugins : (pluginIds...) ->
    @plugins = {}
    if Object.prototype.toString.call(pluginIds[0]) is '[object Array]'
      for pluginId in pluginIds[0]
        @loadPlugin pluginId
    else
      for pluginId in pluginIds
        @loadPlugin pluginId
    return

  loadPlugin : (pluginId) ->
    pluginPath = "../plugins/#{pluginId}"
    module = require pluginPath
    plugin = module.init @, pluginId, process.argv, if @options.config then @options.plugins[pluginId]
    plugin.setLoggingEnabled @isLoggingEnabled()
    if plugin.getEventNames().length
      @logEvent 'bot', 'plugin.configure', plugin.getName(), plugin.getEventNames()
    @plugins[pluginId] = plugin
    @logEvent 'bot', 'plugin.loaded', plugin.getName()
    return

  getPlugin : (pluginId) ->
    @plugins[pluginId]

  init : ->
    @logEvent 'bot', 'initialized'

  logEvent : (plugin, event, messages...) ->
    @emitter.emit 'logger.event', plugin, event, messages


emitter = new EventEmitter2
  wildcard : true
  delimiter : '.'
  maxListeners : 30


exports.Bot = Bot
exports.Logger = Logger
exports.emitter = emitter