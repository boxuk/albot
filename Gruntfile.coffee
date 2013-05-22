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
      covershot:
        cmd: 'mkdir -p covershot/data && ./node_modules/covershot/bin/covershot covershot/data -f html'

    mochacli: 
      options: 
        reporter: 'spec'
      
      all: ['test/**/*.coffee']
  }

  grunt.registerTask 'test', ['env:test', 'mochacli']
  grunt.registerTask 'coverage', ['env:test', 'coffeeCoverage:lib', 'mochacli', 'exec:covershot']
