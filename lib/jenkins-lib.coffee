console = require 'console'
sys = require 'sys'
{exec} = require 'child_process'
request = require 'request'
http = require 'http'
{File} = require 'file-utils'
Q = require 'q'

puts = (error, stdout, stderr) -> sys.puts stdout


JobState = {}


class JenkinsServer

  loggingEnabled : false

  emitter : null

  constructor : (@emitter) ->

  isLoggingEnabled : -> @loggingEnabled

  setLoggingEnabled : (@loggingEnabled) ->

  setUrl : (@serverUrl = '', @jobName = null) ->
    unless @serverUrl.substring(@serverUrl.length - 1, 1) is '/'
      @serverUrl += '/'

  buildStatusResult : (jsonResponse) ->
    result =
      number : 0
      status : 'UNKNOWN'
      committers : []
      initiators : []
    if jsonResponse?.number
      result =
        buildNumber : jsonResponse.number
        status : unless jsonResponse.building is true then jsonResponse.result else 'BUILDING'
      # responsible for changes
      result.committers = (culprit.fullName for culprit in jsonResponse.culprits when culprit.fullName)
      # responsible for initiating
      result.initiators = (cause.userName for cause in (action.causes[0] for action in jsonResponse.actions when action.causes) when cause.userName)
    return result

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
      (jsonResponse) =>
        oldResult = JobState[jobName]
        newResult = @buildStatusResult jsonResponse
        newResult.jobName = jobName
        newResult.requestUrl = url
        newResult.oldBuildNumber = oldResult?.buildNumber
        newResult.oldStatus = oldResult?.status
        JobState[jobName] = newResult
        deferred.resolve newResult
    ), (
      (jsonResponse) =>
        oldResult = JobState[jobName]
        newResult =
          jobName : jobName
          requestUrl : url
          message : jsonResponse.message
          statusCode : jsonResponse.statusCode
        JobState[jobName] = newResult
        deferred.reject newResult
    ))
    deferred.promise

  registerBuildStateEvent : (type = 'lastBuild', jobName = @jobName, interval = 30) ->
    onDone = (result) =>
      @emitter.emit 'jenkins.job.refreshed', result
      @emitter.emit 'logger.message', 'jenkins', 'job.refreshed', result.jobName, result.status, result.buildNumber
      if result.status is 'BUILDING'
        @emitter.emit 'jenkins.job.building', result
        @emitter.emit 'logger.message', 'jenkins', 'job.building', result.jobName, result.status, result.buildNumber
      else if result.status isnt result.oldStatus
        unless result.oldStatus
          @emitter.emit 'jenkins.job.added', result
          @emitter.emit 'logger.message', 'jenkins', 'job.added', result.jobName, result.status, result.buildNumber
        else
          @emitter.emit 'jenkins.job.status.changed', result
          @emitter.emit 'logger.message', 'jenkins', 'job.status.changed', result.jobName, result.status, result.buildNumber
    onFail = (message) =>
      @emitter.emit 'jenkins.server.error', message
      @emitter.emit 'logger.message', 'jenkins', 'server.error', message
    fn = =>
      @emitter.emit 'logger.message', 'jenkins', 'job.refreshing', jobName, type
      @getBuildState(type, jobName).then(onDone, onFail)
    obj = setInterval fn, interval * 1000
    @emitter.emit 'logger.message', 'jenkins', 'job.interval.added', jobName, type
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


exports.JenkinsServer = JenkinsServer