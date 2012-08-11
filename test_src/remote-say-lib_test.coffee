console = require 'console'
sys = require 'sys'
Q = require('q')
Say = require('../lib/remote-say-lib.js').Say

fileUtils = require 'file-utils'
File = fileUtils.File

###
 ======== A Handy Little Nodeunit Reference ========
 https://github.com/caolan/nodeunit

 Test methods:
   test.expect(numAssertions)
   test.done()
 Test assertions:
   test.ok(value, [message])
   test.equal(actual, expected, [message])
   test.notEqual(actual, expected, [message])
   test.deepEqual(actual, expected, [message])
   test.notDeepEqual(actual, expected, [message])
   test.strictEqual(actual, expected, [message])
   test.notStrictEqual(actual, expected, [message])
   test.throws(block, [error], [message])
   test.doesNotThrow(block, [error], [message])
   test.ifError(value)
###


exports['basics'] =

  setUp: (done) ->
    done()

  tearDown: (done) ->
    done()

  checkRandomFileNamesAreUnique: (test) ->
    filenames = [10]
    test.expect filenames.length
    # generate 10 values
    for value, i in filenames
      filenames[i] = Say.randomFileName()
    # check for each value, that the value exists only one time
    countValue = (value, array) ->
      result = 0
      for item in array when item is value
        result = +1
      return result
    results = ((countValue value, filenames) for value in filenames)
    # assert the computation
    for value, i in filenames
      test.equal results[i], 1, "The fileName \"#{value}\" isn't random."
    test.done()


  noRemoteDefined: (test) ->
    test.expect 1
    say = new Say()
    #say.addRemote 'macplex', 'knalli'
    config = text: 'Hello World', voice: 'Alex'

    Q.ncall(say.convert, say, config)
    .then(()->
      console.info arguments
      test.done()
    ).fail((error)->
      console.info arguments
      test.equals error, 'No remotes defined.'
      test.done()
    )
