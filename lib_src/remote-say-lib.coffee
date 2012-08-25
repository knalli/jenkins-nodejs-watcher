console = require 'console'
sys = require 'sys'
{exec} = require 'child_process'
{File} = require 'file-utils'
Q = require 'q'

puts = (error, stdout, stderr) -> sys.puts stdout


class Say

  @LOGGING : false

  constructor : (@remotes = []) ->

  @randomFileName : (extension = 'wave') ->
    "random-audio-file-#{Math.round(Math.random() * 1000000)}.#{extension}"

  @escapeForShell = (line) ->
    '"' + line.replace(/(["\s'$`\\])/g, '\\$1') + '"'

  addRemote : (host, user, password = null) ->
    @remotes.push
      host : host
      user : user
      password : if password then password

  getRemotes : ->
    @remotes.slice 0

  convert : (options) ->
    deferred = Q.defer()
    if @remotes[0]
      @convertWithAvailableRemote 0, deferred, options
    else
      deferred.reject 'No remotes defined.'
    deferred.promise

  convertWithAvailableRemote : (remoteIdx, deferred, options, errorMessage) ->
    unless @remotes[remoteIdx]
      deferred.reject "No remote is left: #{errorMessage}"
    else
      @convertWithRemote(remoteIdx, options).then(((fileName) =>
        deferred.resolve fileName, "Remote ##{remoteIdx} #{@remotes[remoteIdx].host} is valid."
        return
      ), ((message) =>
        @convertWithAvailableRemote remoteIdx + 1, deferred, options, message
        return
      ))
    deferred

  convertWithRemote : (remoteIdx, options) ->
    deferred = Q.defer()

    remote = @remotes[remoteIdx]
    fileName = Say.randomFileName()

    onFailDoReject = (error) ->
      deferred.reject error, remoteIdx
      return
    onDone = ->
      deferred.resolve fileName
      return

    @checkRemoteHostAvailability(remote).then((() =>
      @requestConvert(remote, fileName, options).then((=>
        @remoteCopy(remote, fileName).then((=>
          @remoteDelete(remote, fileName).then(onDone, onFailDoReject)
        ), onFailDoReject)
      ), onFailDoReject)
    ), onFailDoReject)

    deferred.promise

  @buildRemoteHostAvailabilityCommand : (remote) ->
    "ping -c1 #{remote.host}"

  @buildSayCommand : (fileName, options) ->
    "say -o #{fileName} -v #{options.voice} \"#{Say.escapeForShell(options.text)}\""

  @buildSshWithExecCommand : (remote, commandLine) ->
    "ssh #{remote.user}@#{remote.host} -C \"#{Say.escapeForShell(commandLine)}\""

  @buildScpCommand : (remote, fileName) ->
    "scp #{remote.user}@#{remote.host}:#{fileName} #{fileName}"

  checkRemoteHostAvailability : (remote) ->
    command = Say.buildRemoteHostAvailabilityCommand remote
    deferred = Q.defer()
    Q.ncall(exec, null, command)
    .then((stdout, stderr) -> deferred.resolve stdout)
    .fail((error) -> deferred.reject error)
    deferred.promise

  requestConvert : (remote, fileName, options) ->
    commandLine = Say.buildSayCommand fileName, options
    command = Say.buildSshWithExecCommand remote, commandLine
    deferred = Q.defer()
    Q.ncall(exec, null, command)
    .then((stdout, stderr) -> deferred.resolve stdout)
    .fail((error) -> deferred.reject error)
    deferred.promise

  remoteCopy : (remote, fileName) ->
    command = Say.buildScpCommand remote, fileName
    deferred = Q.defer()
    Q.ncall(exec, null, command)
    .then((stdout, stderr) -> deferred.resolve stdout)
    .fail((error) -> deferred.reject error)
    deferred.promise

  remoteDelete : (remote, fileName) ->
    command = Say.buildSshWithExecCommand remote, "rm #{fileName}"
    deferred = Q.defer()
    Q.ncall(exec, null, command)
    .then((stdout, stderr) -> deferred.resolve stdout)
    .fail((error) -> deferred.reject error)
    deferred.promise


exports.Say = Say