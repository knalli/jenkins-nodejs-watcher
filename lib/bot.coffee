{EventEmitter2} = require 'eventemitter2'
OptParse = require 'optparse'


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
      # if this method was called with an array
      for pluginId in pluginIds[0]
        @loadPlugin pluginId
    else
      # otherwise called with multiple arguments
      for pluginId in pluginIds
        @loadPlugin pluginId
    return

  buildPluginOptionParser : (pluginId, pluginOptions, targetOptions) ->
    settings = []

    # Build up settings according OptParse.OptionParser constructor.
    for own key, config of pluginOptions
      settings.push ["-#{pluginId}#{config.alias}", "--#{pluginId}-#{key}#{if config.value then ' VALUE'}", "#{config.description || ''}"]
      if config.default isnt undefined
        targetOptions[key] = config.default
    parser = new OptParse.OptionParser settings
    parser.banner = "Usage plugin #{pluginId}"

    # Build up parser callbacks.
    for own key, config of pluginOptions
      parser.on "#{pluginId}-#{key}", (opt, value) =>
        parsed = if config.parse
          config.parse.apply @, arguments
        else
          value
        @logEvent 'bot', 'loadPlugin', "Setting #{pluginId}.#{key} = #{parsed}"
        targetOptions[key] = parsed
        return

    return parser

  loadPlugin : (pluginId) ->
    pluginPath = "../plugins/#{pluginId}"
    module = require pluginPath

    options = {}

    if module.config?.options

      parser = @buildPluginOptionParser pluginId, module.config.options, options

      # We have to build a pseudo arguments array if the config file was used.
      if @options.config
        # Create a copy of process' arguments array and cut off all except the first.
        args = process.argv.slice(0).splice(0, 2)
        for own key, value of @options.plugins[pluginId]
          args.push "--#{pluginId}-#{key}"
          # Well, if we support sub objects in the future, here would be the place for that...
          # Ignore implicit options.
          args.push("#{value}") if value isnt true
        parser.parse args
      else
        parser.parse process.argv

    plugin = module.init @, pluginId
    plugin.setOptions options
    plugin.setLoggingEnabled @isLoggingEnabled()
    if plugin.getEventNames().length
      @logEvent 'bot', 'plugin.configure', plugin.getName(), plugin.getEventNames()
    @plugins[pluginId] = plugin

    @logEvent 'bot', 'plugin.loaded', plugin.getName()

    return

  getPlugin : (pluginId) -> @plugins[pluginId]

  init : -> @logEvent 'bot', 'initialized'

  logEvent : (plugin, event, messages...) -> @emitter?.emit 'logger.event', plugin, event, messages

  showPluginHelp : (pluginId) ->
    pluginPath = "../plugins/#{pluginId}"
    module = require pluginPath

    if module
      if module.config?.options
        parser = @buildPluginOptionParser pluginId, module.config.options, {}
        console.log parser.toString()
      else
        console.log 'No help available.'


emitter = new EventEmitter2
  wildcard : true
  delimiter : '.'
  maxListeners : 30


exports.Bot = Bot
exports.Logger = Logger
exports.emitter = emitter