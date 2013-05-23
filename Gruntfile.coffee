module.exports = (grunt) ->

  grunt.loadNpmTasks 'grunt-env'
  grunt.loadNpmTasks 'grunt-exec'
  grunt.loadNpmTasks 'grunt-mocha-cli'
  grunt.loadNpmTasks 'grunt-coffee-coverage'

  grunt.initConfig {
    env:
      test: 
        NODE_ENV: 'test'

    coffeeCoverage:
      lib:
        src: 'lib/'
        dest: 'lib-cov/'

    exec:
      html:
        cmd: 'mkdir -p covershot/data && ./node_modules/covershot/bin/covershot covershot/data -f html'
      lcov:
        cmd: 'mkdir -p covershot/data && ./node_modules/covershot/bin/covershot covershot/data -f lcov'
      coveralls:
        cmd: 'cat covershot/coverage.lcov | ./node_modules/coveralls/bin/coveralls.js'

    mochacli: 
      options: 
        reporter: 'spec'
      
      all: ['test/**/*.coffee']
  }

  grunt.registerTask 'test', ['env:test', 'mochacli']
  grunt.registerTask 'coverage:local', ['env:test', 'coffeeCoverage:lib', 'mochacli', 'exec:html']
  grunt.registerTask 'coverage:travis', ['env:test', 'coffeeCoverage:lib', 'mochacli', 'exec:lcov', 'exec:coveralls']
