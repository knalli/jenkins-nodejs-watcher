module.exports = function (grunt) {

  // Project configuration.
  grunt.initConfig({
    pkg : '<json:package.json>',
    test : {
      files : [ 'test/**/*.js' ]
    },
    coffee : {
      test : {
        files : [ 'test_src/remote-say-lib_test.coffee' ],
        dest : 'test/remote-say-lib_test.js'
      }
    },
    lint : {
      files : [ 'grunt.js' ]
    },
    watch : {
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