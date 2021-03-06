/**
 * sass compiling tasks
 * sass: http://sass-lang.com/
 */
module.exports = function(grunt){

  var log = grunt.log;

  function handleResult(from, dest, err, stdout, code, done) {
    if(err){
      grunt.helper('growl', 'SASS COMPILING GOT ERROR', stdout);
      log.writeln(from + ': failed to compile to ' + dest + '.');
      log.writeln(stdout);
      done(false);
    }else{
      log.writeln(from + ': compiled to ' + dest + '.');
      done(true);
    }
  }

  grunt.registerHelper('sass', function(src, dest, done) {
    var args = {
      cmd: 'sass',
      args: [ src, dest ]
    };
    grunt.helper('exec', args, function(err, stdout, code){
      handleResult(src, dest, err, stdout, code, done);
    });
    return true;
  });

  grunt.registerMultiTask('sass', 'compile sass', function() {
    var done = this.async();
    var src = this.data.src;
    var dest = this.data.dest;
    grunt.helper('sass', src, dest, done);
    return true;
  });

};