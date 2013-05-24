module.exports = (grunt) ->

  # Load all grunt tasks available
  require('matchdep').filterDev('grunt-*').forEach(grunt.loadNpmTasks)

  grunt.initConfig {
    bin:
      covershot: './node_modules/covershot/bin/covershot'
      coveralls: './node_modules/coveralls/bin/coveralls.js'

    env:
      test:
        NODE_ENV: 'test'

    coffeelint:
      app: [ '*.coffee', 'lib/**/*.coffee' ]

    mochacli:
      options:
        reporter: 'spec',
        globals: ['data']
      
      all: ['test/**/*.coffee']

    coffeeCoverage:
      lib:
        src: 'lib/'
        dest: 'lib-cov/'

    exec:
      prepcov:
        cmd: 'mkdir -p covershot/data'
      htmlcov:
        cmd: '<%= bin.covershot %> covershot/data -f html'
      lcov:
        cmd: '<%= bin.covershot %> covershot/data -f lcov'
      coveralls:
        cmd: 'cat covershot/coverage.lcov | <%= bin.coveralls %>'

    clean:
      coverage: ['lib-cov']
  }

  grunt.registerTask 'test', [
    'env:test',
    'coffeelint',
    'mochacli'
  ]

  grunt.registerTask 'coverage:instrument', [
    'exec:prepcov',
    'coffeeCoverage:lib',
  ]

  grunt.registerTask 'coverage:html', [
    'coverage:instrument',
    'test',
    'exec:htmlcov',
    'clean:coverage'
  ]

  grunt.registerTask 'coverage:travis', [
    'coverage:instrument',
    'test'
    'exec:lcov',
    'exec:coveralls'
  ]

  grunt.registerTask 'default', ['test']
