
'use strict'

/*global module:false*/
module.exports = function(grunt) {

  grunt.loadNpmTasks('grunt-mocha-cli');
  grunt.loadNpmTasks('grunt-env');

  grunt.initConfig({
    env: {
      test: {
        NODE_ENV : 'test',
      }
    },
    mochacli: {
      options: {
        reporter: 'spec'
      },
      all: ['test/**/*.coffee']
    }
  });

  grunt.registerTask('test', ['env:test', 'mochacli']);
};
