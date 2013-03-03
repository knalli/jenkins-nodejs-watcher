# jenkins-nodejs-watcher [![Dependency Status](https://gemnasium.com/knalli/jenkins-nodejs-watcher.png)](https://gemnasium.com/knalli/jenkins-nodejs-watcher)

A command line util watching for job result actions of a Jenkins server. A job status change will be used generating an audio with OS X' _say_ command via ssh.

## Getting Started
Install the module with: `npm install jenkins-watcher`

```bash
jenkins-watcher -h
```

## Dependencies ##
This module uses following npm modules:
* "console"
* "sys"
* "child_process".exec
* "request"
* "http"
* "file-utils".File
* "q"
* "eventemitter2".EventEmitter2
* "sprintf".sprintf
* "fs"
* "getopt"

## Documentation
_(Coming soon)_

### Text-to-Speech ###

#### OS X Say ####
_(Coming soon)_

#### Alternatives ####
_(Coming soon)_

## Examples

```bash
jenkins-watcher -a -R user@mac.example.org -s http://myjenkins.example.org/jenkins -j job1,job2,job3/lastStableBuild
```

_(Coming soon)_

## Contributing
In lieu of a formal styleguide, take care to maintain the existing coding style. Add unit tests for any new or changed functionality. Lint and test your code using [grunt](https://github.com/cowboy/grunt).

## Release History
_(Nothing yet)_

## License
Copyright (c) 2012 Jan Philipp  
Licensed under the MIT license.
