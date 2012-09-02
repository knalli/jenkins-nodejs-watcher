class Plugin

  loggingEnabled : false

  bot : null

  pluginId : null

  options : null

  constructor : (@bot, @pluginId) ->
    @options = {}

  getName : -> 'Unknown Plugin name'

  getEventNames : -> []

  isLoggingEnabled : -> @loggingEnabled

  setLoggingEnabled : (@loggingEnabled) ->

  log : (event, messages...) ->
    bot?.getEmitter()?.emit @pluginId, event, messages

  setOptions : (@options) ->

  getOption : (key) -> @options[key]


exports.Plugin = Plugin