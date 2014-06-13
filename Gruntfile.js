'use strict';

module.exports = function(grunt) {
    grunt.initConfig({
        yaml: {
            tests: {
                files: [
                    {expand: true, cwd: 'tests/', src: ['**/*.yml'], dest: 'tests/build/'}
                ]
            }
        },
        jison: {
            webidl : {
                files: { 'lib/webidl.js': 'src/webidl.y' }
            }
        },
        nodeunit: {
            files: ['tests/test-runner.js']
        },
        watch: {
            yaml: {
                files: ['tests/**/*.yml'],
                tasks: ['yaml'],
                options: {
                    interrupt: true
                }
            },
            jison: {
                files: ['src/webidl.y'],
                tasks: ['jison', 'nodeunit'],
                options: {
                    interrupt: true
                }
            },
            tests: {
                files: ['tests/build/**/*.json', 'tests/test-runner.js'],
                tasks: ['nodeunit'],
                options: {
                    interrupt: true
                }
            }
        }
    });

    grunt.loadNpmTasks('grunt-yaml');
    grunt.loadNpmTasks('grunt-contrib-nodeunit');
    grunt.loadNpmTasks('grunt-contrib-watch');

    grunt.loadNpmTasks('grunt-jison');
    grunt.registerTask('default', ['jison', 'yaml', 'nodeunit']);
};
