#!/usr/bin/env coffee

sys = require 'sys'
{exec} = require 'child_process'
Q = require 'q'
{jenkinsServer, jenkinsEmitter} = require '../lib_src/jenkins-lib'
{Say} = require '../lib_src/remote-say-lib'
{sprintf} = require 'sprintf'
fs = require 'fs'
path = require 'path'
{File} = require 'file-utils'
{ServerFactory} = require '../lib_src/server-lib'
{LocaleTempFileRepository} = require '../lib_src/tempfile-repo-lib'
OptParse = require 'optparse'
{Bot} = require '../lib_src/bot'

LOGGING = true
jenkinsServer.LOGGING = LOGGING
Say.LOGGING = LOGGING

###
Configuration & User Options
###

Switches = [
  [ '-l', '--skip-first BOOLEAN', 'Skip first']
  [ '-r', "--remote [user[:password]@]host", "A ssh remote to connect when using the T2S api. This can be a comma separated list or multiple ones." ]
  [ '-u', "--jenkins-url URL", "Jenkins server url" ]
  [ '-j', "--jenkins-job job/type", 'A job in the format "job[/type]". This can be list of comma separated list. "type" has the default "lastBuild" and can have the following jenkins types: lastBuild, lastStableBuild, lastSuccessfulBuild, lstFailedBuild, lastUnsuccessfulBuild' ]
  [ '-t', "--text-file filename", "Specify a path to an alternative JSON file with texts." ]
  [ '-p', "--plugins name", "Specify a plugin by its name. This can be a list of comma separated list." ]
]

Options =
  'skip-first' : false
  'remote' : []
  'jenkins-url' : ''
  'jenkins-job' : []
  'text-voice' : 'Alex'
  'text-file' : __dirname + '/texts.json'
  'plugins' : []

Parser = new OptParse.OptionParser Switches
Parser.banner = "Usage jenkins-watcher [options]"

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
    Options['plugins'].push pluginId

Parser.on "text-file", (opt, value) ->
  Options['text-file'] = value

Parser.on "help", (opt, value) ->
  console.log Parser.toString()
  process.exit 0

Parser.parse process.argv

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

class AudioShadowSpeaker

# intellij coffeescript formatter workaround
  _ : undefined

  # Storing all generated files (audios).
  fileRepository : null

  remoteSay : null

  constructor : (remotes) ->
    @fileRepository = new LocaleTempFileRepository()
    @remoteSay = new Say()
    for remote in remotes
      if LOGGING then console.log "Registering remote #{remote.host}."
      @remoteSay.addRemote remote.host, remote.username, remote.password

  text2speech : (text, voice = Options['text-voice']) ->
    params = text : text, voice : voice
    done = (fileName) =>
      console.info "AudioShadowSpeaker.text2speech >> Audio file created and copied: #{fileName}"
      @fileRepository.add fileName
      path = new File("../#{fileName}").getAbsolutePath()
      jenkinsEmitter.emit 'audio.create', path
    fail = ->
      console.warn arguments
      process.exitCode 1
    @remoteSay.convert(params).then done, fail
    return

  deleteAudio : (fileName) ->
    @fileRepository.remove fileName

  getAudioFile : (fileName) ->
    @fileRepository.get fileName

speaker = new AudioShadowSpeaker(Options.remote)

# Check that at least a server and one job was defined.
if !Options['jenkins-url'] || !Options['jenkins-job']?.length
  sys.puts 'Please define a server and at least one job.'
  console.log Parser.toString()
  process.exit 1

jenkinsEmitter.on 'job.refresh', (result) ->
  if (LOGGING) then console.log "JOB REFRESHED >> #{result.jobName} = #{result.result}"

jenkinsEmitter.on 'job.result.add', (result, jobName, buildNumber) ->
  unless Options.skipFirst
    if LOGGING then console.log "JOB ADDED >> #{jobName} ##{buildNumber} = #{result}"
    text = sprintf(Labels.getRandom('onJobRegister'), jobName, buildNumber, result)
    if LOGGING then console.log "JOB ADDED >> TEXT = #{text}"
    speaker.text2speech text
  else
    if LOGGING then console.log "JOB ADDED >>Option skipFirst was enabled, so the first job state will be skipped."

jenkinsEmitter.on 'job.result.update', (result, jobName, buildNumber) ->
  if LOGGING then console.log '-> job.result.update'
  text = switch result
    when 'SUCCESS', 'STABLE'
      sprintf(Labels.getRandom('onJobSwitchedToStable'), jobName, buildNumber, result)
    when 'FAILURE'
      sprintf(Labels.getRandom('onJobSwitchedToFailure'), jobName, buildNumber, result)
    when 'UNSTABLE'
      sprintf(Labels.getRandom('onJobSwitchedToUnstable'), jobName, buildNumber, result)
    else
      'Undefined state for job ' + jobName

  if LOGGING then console.log 'TEXT = ' + text
  speaker.text2speech text

jenkinsEmitter.on 'server.down', ->
  if LOGGING then console.log 'Server down:', arguments
  text = sprintf(Labels.getRandom('onServerDown'))
  if LOGGING then console.log 'TEXT = ' + text
  speaker.text2speech text

jenkinsEmitter.on 'server.up', ->
  if LOGGING then console.log 'Server up:', arguments
  text = sprintf(getRandomText('onServerUp'))
  if LOGGING then console.log 'TEXT = ' + text
  speaker.text2speech text

###
 Recall the current options
###
console.log "Jenkins Server Url = #{Options['jenkins-url']}"
if Options.remote.length
  console.log "Following #{Options.remote.length} remotes are defined:"
  for remote, i in Options.remote
    console.log "  ##{i}: #{remote.host}"
else
  console.log "No remote is defined."

### Main ###

jenkinsServer.setUrl(Options['jenkins-url'])

bot = new Bot(jenkinsEmitter)
bot.loadPlugins Options.plugins

Q.ncall(fs.readFile, null, Options['text-file'], 'utf8').then(((data) ->
  console.log 'Texts loaded from file ' + Options['text-file']

  try
    Labels.texts = JSON.parse(data)
  catch exception
    sys.puts(exception)

  ServerFactory.initServer '.', 8888, (success, localeFilePath, requestUrl) ->
    if success then speaker.deleteAudio localeFilePath

  for job in Options['jenkins-job']
    jenkinsServer.registerBuildStateEvent job.type, job.name, 10

), ( (error) ->
  sys.puts 'Could not find or read the file: ' + Options['text-file']
  sys.puts error
  process.exit 1

))