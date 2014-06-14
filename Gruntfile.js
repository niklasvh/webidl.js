'use strict';

module.exports = function(grunt) {
    grunt.initConfig({
        jison: {
            webidl : {
                files: { 'lib/webidl.js': 'src/webidl.y' }
            }
        },
        nodeunit: {
            files: ['tests/test-runner.js']
        },
        watch: {
            jison: {
                files: ['src/webidl.y'],
                tasks: ['jison', 'nodeunit'],
                options: {
                    interrupt: true
                }
            },
            tests: {
                files: ['tests/*'],
                tasks: ['nodeunit'],
                options: {
                    interrupt: true
                }
            }
        }
    });

    grunt.loadNpmTasks('grunt-contrib-nodeunit');
    grunt.loadNpmTasks('grunt-contrib-watch');

    grunt.loadNpmTasks('grunt-jison');
    grunt.registerTask('default', ['jison', 'nodeunit']);
};
