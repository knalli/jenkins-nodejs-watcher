class Plugin

  loggingEnabled : false

  constructor : (@bot) ->

  getName : -> 'Unknown Plugin name'

  getEventNames : -> []

  isLoggingEnabled : -> @loggingEnabled

  setLoggingEnabled : (@loggingEnabled) ->


exports.Plugin = Plugin