LOGGING = true

console = require 'console'
sys = require 'sys'
{exec} = require 'child_process'
request = require 'request'
http = require 'http'
{File} = require 'file-utils'
Q = require 'q'
{EventEmitter2} = require 'eventemitter2'

puts = (error, stdout, stderr) -> sys.puts stdout


Emitter = new EventEmitter2
  wildcard : true
  delimiter : '.'
  maxListeners : 20


JobState = {}


class ServerImpl

  @LOGGING : false

  setUrl : (@serverUrl = '', @jobName = null) ->
    unless @serverUrl.substring(@serverUrl.length - 1, 1) is '/'
      @serverUrl += '/'

  getLastStableBuild : (jobName = null) -> @getJobBuildNumberByType 'lastStableBuild', jobName

  getJobBuildNumberByType : (state, jobName = @jobName) ->
    url = "#{@serverUrl}job/#{jobName}/#{state}/api/json"
    deferred = Q.defer()
    @request(url).then((
      (responseJson) ->
        #the 1st response value is the actual request-response
        if responseJson.number
          deferred.resolve
            requestUrl : url
            buildNumber : responseJson.number
        else
          deferred.reject
            requestUrl : url
            buildNumber : 0
    ), (
      (responseJson) ->
        deferred.reject
          requestUrl : url
          message : responseJson.message
          statusCode : responseJson.statusCode
    ))
    deferred.promise

  getBuildState : (type = 'lastBuild', jobName = @jobName) ->
    url = "#{@serverUrl}job/#{jobName}/#{type}/api/json"
    deferred = Q.defer()
    @request(url).then((
      (responseJson) =>
        oldResult = JobState[jobName]
        if responseJson.number
          newResult =
            jobName : jobName
            requestUrl : url
            buildNumber : responseJson.number
            result : responseJson.result
            oldBuildNumber : oldResult?.buildNumber
            oldResult : oldResult?.result
          JobState[jobName] = newResult
          deferred.resolve newResult
        else
          newResult =
            jobName : jobName
            requestUrl : url
            buildNumber : 0
            result : 'UNKNOWN'
            oldBuildNumber : oldResult?.buildNumber
            oldResult : oldResult?.result
          JobState[jobName] = newResult
          deferred.reject newResult
    ), (
      (responseJson) =>
        oldResult = JobState[jobName]
        newResult =
          jobName : jobName
          requestUrl : url
          message : responseJson.message
          statusCode : responseJson.statusCode
        JobState[jobName] = newResult
        deferred.reject newResult
    ))
    deferred.promise

  registerBuildStateEvent : (type = 'lastBuild', jobName = @jobName, interval = 30) ->
    onDone = (result) =>
      Emitter.emit 'job.refresh', result
      if result.result isnt result.oldResult
        Emitter.emit 'job.result', result
        if result.oldResult
          Emitter.emit 'job.result.update', result.result, jobName, result.buildNumber
        else
          Emitter.emit 'job.result.add', result.result, jobName, result.buildNumber
    onFail = (message) =>
      Emitter.emit 'jenkinsServer.error', message
    fn = =>
      if @LOGGING then console.log "LOG :: getBuildState('#{type}', '#{jobName}')"
      @getBuildState(type, jobName).then(onDone, onFail)
    obj = setInterval fn, interval * 1000
    if @LOGGING then console.log "LOG :: New intervall installed: #{jobName}/#{type}"
    fn()
    return obj

  deregister : (intervalObj) ->
    clearInterval intervalObj

  request : (url) ->
    deferred = Q.defer()

    onDone = (response) ->
      if response[0].statusCode is 200
        deferred.resolve JSON.parse response[1]
      else
        deferred.reject
          statusCode : response[0].statusCode
          message : 'Not available'
    onFail = (response) ->
      deferred.reject
        message : response.toString()

    config =
      method : 'GET'
      url : url
      followAllRedirects : true
    Q.ncall(request, null, config).then(onDone, onFail)

    deferred.promise


exports.JenkinsServer = new ServerImpl
exports.JenkinsEmitter = Emitter