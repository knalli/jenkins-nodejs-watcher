#!/usr/bin/env coffee

sys = require 'sys'
{exec} = require 'child_process'
Q = require 'q'
{jenkinsServer, jenkinsEmitter} = require '../lib/jenkins-lib'
{Say} = require '../lib/remote-say-lib'
{sprintf} = require 'sprintf'
fs = require 'fs'
path = require 'path'
{File} = require 'file-utils'
{LocaleTempFileRepository} = require '../lib/tempfile-repo-lib'
OptParse = require 'optparse'
{Bot} = require '../lib/bot'

LOGGING = false
jenkinsServer.setLoggingEnabled LOGGING

# TODO
emitter = jenkinsEmitter

###
Configuration & User Options
###

Switches = [
  [ '-h', '--help plugin', 'Show this help. If a plugin is specified, the help of this plugin will be displayed.']
  [ '-c', '--config file', 'Provide a configuration file.' ]
  [ '-l', '--skip-first BOOLEAN', 'Skip first']
  [ '-r', "--remote [user[:password]@]host", "A ssh remote to connect when using the T2S api. This can be a comma separated list or multiple ones." ]
  [ '-u', "--jenkins-url URL", "Jenkins server url" ]
  [ '-j', "--jenkins-job job/type", 'A job in the format "job[/type]". This can be list of comma separated list. "type" has the default "lastBuild" and can have the following jenkins types: lastBuild, lastStableBuild, lastSuccessfulBuild, lstFailedBuild, lastUnsuccessfulBuild' ]
  # TODO This option will be dismissed later in favor of a dedicated plugin.
  [ '-t', "--text-voice voice", "Specify the text voice." ]
  [ '-t', "--text-file filename", "Specify a path to an alternative JSON file with texts." ]
  [ '-p', "--plugins name", "Specify a plugin by its name. This can be a list of comma separated list." ]
]

Options =
  'config' : null
  'skip-first' : false
  'remote' : []
  'jenkins-url' : ''
  'jenkins-job' : []
  'text-voice' : 'Alex'
  'text-file' : __dirname + '/texts.json'
  'plugins' : []

Parser = new OptParse.OptionParser Switches
Parser.banner = "Usage jenkins-watcher [options]"

Parser.on 'config', (opt, value) ->
  Options.config = value

Parser.on "remote", (opt, value) ->
  return unless value?.split(',').length
  for remote in (remote.split('@') for remote in value.split(',')) when remote.length
    switch remote?.length
      when 1
        Options.remote.push host : remote[0]
        break
      when 2
        userParts = remote[0].split ':'
        Options.remote.push username : userParts[0], password : userParts[1], host : remote[1]
        break
      else
        sys.puts "A remote has an invalid format: #{remote}"
        process.exit 1
        break


Parser.on "jenkins-url", (opt, value) ->
  Options['jenkins-url'] = value

Parser.on "jenkins-job", (opt, value) ->
  return unless value?.split(',').length
  for parts in (job.split('/') for job in value.split(',')) when parts.length
    Options['jenkins-job'].push
      name : parts[0]
      type : if parts.length < 2 then 'lastBuild' else parts[1]

Parser.on "plugins", (opt, value) ->
  return unless value?.split(',').length
  for pluginId in value.split(',')
    Options['plugins'][pluginId] = {}

Parser.on "text-file", (opt, value) ->
  Options['text-file'] = value

Parser.on "text-voice", (opt, value) ->
  Options['text-voice'] = value

Parser.on "help", (opt, value) ->
  if value
    try
      pluginPath = "../plugins/#{value}"
      plugin = require pluginPath
    catch exception
      console.warn "Plugin #{value} could not be found."
    if plugin
      if plugin.help
        plugin.help()
      else
        console.warn "This plugin does not provide any help."
  else
    console.log Parser.toString()
  process.exit 0

###
Parsing complete.
###

# A small helper class.
class Labels
  @texts :
    {}
  @getRandom = (key) ->
    texts = Labels.texts[key]
    idx = Math.floor(Math.random() * texts.length)
    return texts[idx]

class PhoneticHelper
  @improveJobName : (jobName) ->
    for job in Options['jenkins-job'] when job.name is jobName
      return job.soundName or jobName
    return jobName

class AudioShadowSpeaker

# intellij coffeescript formatter workaround
  _ : undefined

  # Storing all generated files (audios).
  fileRepository : null

  remoteSay : null

  constructor : (remotes) ->
    @fileRepository = new LocaleTempFileRepository()
    @remoteSay = new Say()
    @remoteSay.setTransformToMp3 true
    for remote in remotes
      if LOGGING then console.log "Registering remote #{remote.host}."
      @remoteSay.addRemote remote.host, remote.username, remote.password

  text2speech : (text, voice = Options['text-voice']) ->
    params = text : text, voice : voice
    done = (fileName) =>
      if LOGGING then console.info "AudioShadowSpeaker.text2speech >> Audio file created and copied: #{fileName}"
      @fileRepository.add fileName
      path = new File("../#{fileName}").getAbsolutePath()
      emitter.emit 'audio.create', path, fileName
    fail = ->
      console.warn arguments
      process.exitCode 1
    @remoteSay.convert(params).then done, fail
    return

  deleteAudio : (fileName) ->
    @fileRepository.remove fileName

  getAudioFile : (fileName) ->
    @fileRepository.get fileName


###
  Main
###

readConfiguration = ->
  Parser.parse process.argv
  if Options.config
    deferred = Q.defer()
    Q.ncall(fs.readFile, null, Options.config, 'utf8').then(((data)->
      try
        config = JSON.parse data
        if config.main
          for own key, value of config.main
            Options[key] = value
        if config.plugins
          Options.plugins = config.plugins
      catch exception
        console.warn "Configuration file is not in a valid JSON format", exception
        throw e
      deferred.resolve()
    ), (()->
      deferred.reject()
    ))
    deferred.promise
  else
    Q.fcall(->)

readConfiguration().then((->

  # Check that at least a server and one job was defined.
  if !Options['jenkins-url'] || !Options['jenkins-job']?.length
    sys.puts 'Please define a server and at least one job.'
    console.warn Parser.toString()
    process.exit 1

  speaker = new AudioShadowSpeaker(Options.remote)
  bot = new Bot(emitter, Options)
  bot.setLoggingEnabled LOGGING
  pluginIds = (pluginId for pluginId, pluginConfig of Options.plugins)
  bot.loadPlugins pluginIds

  jenkinsServer.setUrl Options['jenkins-url']

  emitter.on 'job.refresh', (result) ->
    if (LOGGING) then console.log "JOB REFRESHED >> #{result.jobName} = #{result.result}"

  emitter.on 'job.result.add', (result, jobName, buildNumber) ->
    unless Options.skipFirst
      if LOGGING then console.log "JOB ADDED >> #{jobName} ##{buildNumber} = #{result}"
      text = sprintf(Labels.getRandom('onJobRegister'), PhoneticHelper.improveJobName(jobName), buildNumber, Labels.getRandom(result))
      if LOGGING then console.log "JOB ADDED >> TEXT = #{text}"
      speaker.text2speech text
    else
      if LOGGING then console.log "JOB ADDED >>Option skipFirst was enabled, so the first job state will be skipped."

  emitter.on 'job.result.update', (result, jobName, buildNumber) ->
    if LOGGING then console.log '-> job.result.update'
    if LOGGING then console.log 'Culprits for this state: ' + result.culprits
    text = switch result
      when 'SUCCESS', 'STABLE'
        sprintf(Labels.getRandom('onJobSwitchedToStable'), PhoneticHelper.improveJobName(jobName), buildNumber, Labels.getRandom(result))
      when 'FAILURE'
        sprintf(Labels.getRandom('onJobSwitchedToFailure'), PhoneticHelper.improveJobName(jobName), buildNumber, Labels.getRandom(result))
      when 'UNSTABLE'
        sprintf(Labels.getRandom('onJobSwitchedToUnstable'), PhoneticHelper.improveJobName(jobName), buildNumber, Labels.getRandom(result))
      else
        'Undefined state for job ' + jobName

    if LOGGING then console.log 'TEXT = ' + text
    speaker.text2speech text

  emitter.on 'server.down', ->
    if LOGGING then console.log 'Server down:', arguments
    text = sprintf(Labels.getRandom('onServerDown'))
    if LOGGING then console.log 'TEXT = ' + text
    speaker.text2speech text

  emitter.on 'server.up', ->
    if LOGGING then console.log 'Server up:', arguments
    text = sprintf(getRandomText('onServerUp'))
    if LOGGING then console.log 'TEXT = ' + text
    speaker.text2speech text

  Q.ncall(fs.readFile, null, Options['text-file'], 'utf8').then(((data) ->
    if LOGGING then console.log 'Texts loaded from file ' + Options['text-file']

    try
      Labels.texts = JSON.parse(data)
    catch exception
      sys.puts(exception)

    bot.getEmitter().on 'http.request', (success, localeFilePath) ->
      if LOGGING then console.log "Http.request #{localeFilePath}"
      if success then speaker.deleteAudio localeFilePath

    for job in Options['jenkins-job']
      jenkinsServer.registerBuildStateEvent job.type, job.name, 10

  ), ( (error) ->
    sys.puts 'Could not find or read the file: ' + Options['text-file']
    sys.puts error
    process.exit 1

  ))

), (->
  console.warn 'Could not read configuration.'
))