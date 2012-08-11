#!/usr/bin/env node
var sys = require('sys');
var exec = require('child_process').exec;
var Q = require('q');
var opt = require('getopt');
var JenkinsLib = require('../lib/jenkins-lib');
var Server = JenkinsLib.Server;
var jenkinsEmitter = JenkinsLib.emitter;
var Say = require('../lib/remote-say-lib').Say;
var sprintf = require('sprintf').sprintf;
var fs = require('fs');

var LOGGING = true;
Server.LOGGING = LOGGING;
Say.LOGGING = LOGGING;

var getRandomText = function (key) {
  var texts = Settings.texts[key];
  var idx = Math.floor(Math.random() * texts.length);
  return texts[idx];
};

var remoteSay = new Say();
var playTextAsAudio = function (text, voice) {
  remoteSay.convert({
    text : text,
    voice: voice
  }).then(function (fileName) {
      exec('afplay ' + fileName, function () {
        exec('rm ' + fileName, function () {
        });
      })
    }, function () {
      console.warn(arguments);
      process.exitCode(1);
    });
};

var Settings = {
  skipFirst: false,
  remotes  : [],
  jobs     : [],
  textVoice: 'Alex',
  textFile : __dirname + '/texts.json',
  texts    : {}
};

try {
  opt.setopt("haR:s:j::t:v:");
} catch (exception) {
  switch (exception.type) {
    case "unknown":
      console.log("Unknown option: -%s", exception.opt);
      break;
    case "required":
      console.log("Required parameter for option: -%s", exception.opt);
      break;
    default:
      console.dir(exception);
  }
  process.exit(0);
}

var showHelp = function () {
  opt.showHelp('Program name', function (option) {
    var nl = '\n                ';
    switch (option) {
      case 'a':
        return 'If set, the first result will be notified.' + nl + 'Otherwise the first result will be skipped (restart mode).';
      case 'h':
        return 'Show this help menu';
      case 'R':
        return 'A remote in the format "[user[:password]@]host".' + nl + 'This can be a list of comma separated list.';
      case 's':
        return 'Jenkins server url';
      case 'j':
        return 'A job in the format "job[/type]".' + nl + 'This can be list of comma separated list.' + nl + '"type" has the default "lastBuild" and can have the following jenkins types: lastBuild, lastStableBuild, lastSuccessfulBuild, lstFailedBuild, lastUnsuccessfulBuild';
      case 't':
        return 'Specify a path to an alternative JSON file with texts.';
      case 'v':
        return 'Specify an alternative OS X voice (default "Alex").';
      default:
        return 'Option "' + option + '"';
    }
  });
};

opt.getopt(function (option, parameter) {
  switch (option) {
    case "h":
      showHelp();
      process.exit(0);
      break;
    case 'R':
      Settings.remotes = [];
      var remotes = parameter[0].split(','), i, remote, remoteParts, userParts;
      for (i = 0; i < remotes.length; i++) {
        remote = remotes[i];
        remoteParts = remote.split('@');

        switch (remoteParts.length) {
          case 1:
            Settings.remotes[i] = {
              host: remoteParts[0]
            };
            break;
          case 2:
            userParts = remoteParts[0].split(':');
            Settings.remotes[i] = {
              username: userParts[0],
              password: userParts[1],
              host    : remoteParts[1]
            };
            break;
          default:
            sys.puts('A remote has an invalid format: ' + remote);
            process.exit(1);
        }
      }
      break;
    case 'a':
      Settings.skipFirst = true;
      break;
    case 's':
      Settings.server = parameter[0];
      break;
    case 'j':
      Settings.jobs = [];
      var paramUris = parameter[0].split(','), parts;
      for (var i = 0; i < paramUris.length; i++) {
        parts = paramUris[i].split('/');
        if (parts.length && parts[0]) {
          if (parts.length < 2) {
            Settings.jobs.push({
              name: parts[0],
              type: 'lastBuild'
            });
          } else {
            Settings.jobs.push({
              name: parts[0],
              type: parts[1]
            });
          }
        } else {
          sys.puts('A job has an invalid format: ' + paramUris[i]);
          process.exit(1);
        }
      }
      break;

    case 'v':
      Settings.textVoice = parameter[0];
      break;
    case 't':
      Settings.textFile = parameter[0];
      break;
  }
});

// Check that at least a server and one job was defined.
if (!Settings.server || !Settings.jobs || !Settings.jobs.length) {
  sys.puts('Please define a server and at least one job.');
  showHelp();
  process.exit(1);
}

for (var i = 0; i < Settings.remotes.length; i++) {
  if (LOGGING) console.log('Registering remote "' + Settings.remotes[i].host + '".');
  remoteSay.addRemote(Settings.remotes[i].host, Settings.remotes[i].username, Settings.remotes[i].password)
}
var jenkinsServer = new Server(Settings.server);

jenkinsEmitter.on('job.refresh', function (result) {
  if (LOGGING) console.log('CMD :: ', result.jobName, result.result);
});

jenkinsEmitter.on('job.result.add', function (result, jobName, buildNumber) {
  if (LOGGING) console.log('-> job.result.add');
  if (!Settings.skipFirst) {
    var text = sprintf(getRandomText('onJobRegister'), jobName, buildNumber, result);
    if (LOGGING) console.log('TEXT = ' + text);
    playTextAsAudio(text, Settings.textVoice);
  }
  if (LOGGING) console.log('-> job.result.add (end)');
});

jenkinsEmitter.on('job.result.update', function (result, jobName, buildNumber) {
  if (LOGGING) console.log('-> job.result.update');
  var text = '';
  switch (result) {
    case 'SUCCESS':
    case 'STABLE':
      text = sprintf(getRandomText('onJobSwitchedToStable'), jobName, buildNumber, result);
      break;
    case 'FAILURE':
      text = sprintf(getRandomText('onJobSwitchedToFailure'), jobName, buildNumber, result);
      break;
    case 'UNSTABLE':
      text = sprintf(getRandomText('onJobSwitchedToUnstable'), jobName, buildNumber, result);
      break;
    default:
      text = 'Undefined state for job ' + jobName;
      break;
  }

  if (LOGGING) console.log('TEXT = ' + text);
  playTextAsAudio(text, Settings.textVoice);
  if (LOGGING) console.log('-> job.result.update (end)');
});

jenkinsEmitter.on('server.down', function () {
  if (LOGGING) console.log('Server down:', arguments);
  var text = sprintf(getRandomText('onServerDown'));
  if (LOGGING) console.log('TEXT = ' + text);
  playTextAsAudio(text, Settings.textVoice);
});

jenkinsEmitter.on('server.up', function () {
  if (LOGGING) console.log('Server up:', arguments);
  var text = sprintf(getRandomText('onServerUp'));
  if (LOGGING) console.log('TEXT = ' + text);
  playTextAsAudio(text, Settings.textVoice);
});

Q.ncall(fs.readFile, null, Settings.textFile, 'utf8').then(function (data) {
  console.log('Texts loaded from file ' + Settings.textFile);
  try {
    Settings.texts = JSON.parse(data);
  } catch (e) {
    sys.puts(e);
  }
  for (var i = 0; i < Settings.jobs.length; i++) {
    var job = Settings.jobs[i];
    jenkinsServer.registerBuildStateEvent(job.type, job.name, 10);
  }
}, function (error) {
  sys.puts('Could not find or read the file: ' + Settings.textFile);
  sys.puts(error);
  process.exit(1);
})