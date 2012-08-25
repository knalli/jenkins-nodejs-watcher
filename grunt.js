module.exports = function (grunt) {

  // Project configuration.
  grunt.initConfig({
    pkg : '<json:package.json>',
    test : {
      files : [ 'test/**/*.js' ]
    },
    coffee : {
      src0 : {
        files : [ 'bin/main.coffee' ],
        dest : 'bin/main.js'
      },
      src1 : {
        files : [ 'lib_src/remote-say-lib.coffee' ],
        dest : 'lib/remote-say-lib.js'
      },
      src2 : {
        files : [ 'lib_src/jenkins-lib.coffee' ],
        dest : 'lib/jenkins-lib.js'
      },
      src3 : {
        files : [ 'lib_src/server-lib.coffee' ],
        dest : 'lib/server-lib.js'
      },
      src4 : {
        files : [ 'lib_src/tempfile-repo-lib.coffee' ],
        dest : 'lib/tempfile-repo-lib.js'
      },
      test : {
        files : [ 'test_src/remote-say-lib_test.coffee' ],
        dest : 'test/remote-say-lib_test.js'
      }
    },
    lint : {
      files : [ 'grunt.js' ]
    },
    watch : {
      coffee_src : {
        files : '<config:coffee.src.files>',
        tasks : 'coffee:src test'
      },
      coffee_test : {
        files : '<config:coffee.test.files>',
        tasks : 'coffee:test test'
      },
      list : {
        files : '<config:lint.files>',
        tasks : 'default'
      }
    },
    jshint : {
      options : {
        curly : true,
        eqeqeq : true,
        immed : true,
        latedef : true,
        newcap : true,
        noarg : true,
        sub : true,
        undef : true,
        boss : true,
        eqnull : true,
        node : true
      },
      globals : {
        exports : true
      }
    }
  });

  grunt.loadTasks('tasks');

  // Default task.
  grunt.registerTask('default', 'coffee lint test');

};