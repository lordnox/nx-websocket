// Generated on 2013-10-14 using generator-angular 0.4.0
'use strict';
var LIVERELOAD_PORT = 35729;
var lrSnippet = require('connect-livereload')({ port: LIVERELOAD_PORT });
var mountFolder = function (connect, dir) {
  console.log('serving: ' + require('path').resolve(dir));
  return connect.static(require('path').resolve(dir));
};

// # Globbing
// for performance reasons we're only matching one level down:
// 'test/spec/{,*/}*.js'
// use this if you want to recursively match all subfolders:
// 'test/spec/**/*.js'

module.exports = function (grunt) {
  require('load-grunt-tasks')(grunt);
  require('time-grunt')(grunt);

  // configurable paths
  var yeomanConfig = {
    app: 'app',
    dist: 'dist',
    test: 'test',
    server: 'test-server',
    tmp: '.tmp'
  };

  try {
    var _bower = require('./bower.json');
    var _package = require('./bower.json');
    yeomanConfig.app = _bower.appPath || yeomanConfig.app;
    yeomanConfig.version = _bower.version || _package.version || yeomanConfig.version;
  } catch (e) {}

  grunt.initConfig({
    yeoman: yeomanConfig,
    watch: {
      coffee: {
        files: ['<%= yeoman.app %>/scripts/{,*/}*.coffee'],
        tasks: ['coffee:dist']
      },
      coffeeTest: {
        files: ['test/*/{,*/}*.coffee'],
        tasks: ['coffee:test']
      },
      styles: {
        files: ['<%= yeoman.app %>/styles/{,*/}*.css'],
        tasks: ['copy:styles', 'autoprefixer']
      },
      e2e: {
        options: {
          livereload: LIVERELOAD_PORT
        },
        files: [
          'Gruntfile.js',
          '<%= yeoman.app %>/**/{,*/}*',
          '<%= yeoman.test %>/**/{,*/}*',
        ],
        tasks: [
          'test:e2e'
        ]
      },
      livereload: {
        options: {
          livereload: LIVERELOAD_PORT
        },
        files: [
          '<%= yeoman.app %>/{,*/}*.html',
          '.tmp/styles/{,*/}*.css',
          '{.tmp,<%= yeoman.app %>}/scripts/{,*/}*.js',
          '<%= yeoman.app %>/images/{,*/}*.{png,jpg,jpeg,gif,webp,svg}',
          'Gruntfile.js'
        ],
        tasks: [
          'connect:dist:restart'
        ]
      },
      server: {
        files: ['Gruntfile.js','<%= yeoman.server %>/{,*/}*'],
      }
    },
    autoprefixer: {
      options: ['last 1 version'],
      dist: {
        files: [{
          expand: true,
          cwd: '.tmp/styles/',
          src: '{,*/}*.css',
          dest: '.tmp/styles/'
        }]
      }
    },
    connect: {
      options: {
        port: 9000,
        // Change this to '0.0.0.0' to access the server from outside.
        hostname: 'localhost'
      },
      livereload: {
        options: {
          middleware: function (connect) {
            return [
              lrSnippet,
              mountFolder(connect, '.tmp'),
              mountFolder(connect, yeomanConfig.app)
            ];
          }
        }
      },
      test: {
        options: {
          middleware: function (connect) {
            return [
              mountFolder(connect, '.tmp'),
              mountFolder(connect, 'test')
            ];
          }
        }
      },
      dist: {
        options: {
          middleware: function (connect) {
            return [
              mountFolder(connect, yeomanConfig.dist)
            ];
          }
        }
      }
    },
    open: {
      server: {
        url: 'http://localhost:<%= connect.options.port %>'
      }
    },
    clean: {
      dist: {
        files: [{
          dot: true,
          src: [
            '.tmp',
            '<%= yeoman.dist %>/*',
            '!<%= yeoman.dist %>/.git*'
          ]
        }]
      },
      server: '.tmp'
    },
    jshint: {
      options: {
        jshintrc: '.jshintrc'
      },
      all: [
        'Gruntfile.js',
        '<%= yeoman.app %>/scripts/{,*/}*.js'
      ]
    },
    coffee: {
      options: {
        sourceMap: true,
        sourceRoot: ''
      },
      dist: {
        files: [{
          expand: true,
          cwd: '<%= yeoman.app %>/scripts',
          src: '{,*/}*.coffee',
          dest: '.tmp/app/scripts',
          ext: '.js'
        }]
      },
      test: {
        files: [{
          expand: true,
          cwd: 'test',
          src: '**/{,*/}*.coffee',
          dest: '.tmp/test/spec',
          ext: '.js'
        }]
      }
    },
    // Put files not handled in other tasks here
    copy: {
      dist: {
        files: [{
          expand: true,
          dot: true,
          cwd: '<%= yeoman.tmp %>/<%= yeoman.app %>/scripts/services',
          dest: '<%= yeoman.dist %>',
          src: '*.js'
        }, {
          expand: true,
          dot: true,
          cwd: '<%= yeoman.tmp %>/<%= yeoman.app %>/scripts/services',
          dest: '<%= yeoman.dist %>',
          src: '*.js.map'
        }]
      },
      styles: {
        expand: true,
        cwd: '<%= yeoman.app %>/styles',
        dest: '.tmp/styles/',
        src: '{,*/}*.css'
      }
    },
    concurrent: {
      server: [
        'coffee:dist',
        'copy:styles'
      ],
      test: [
        'coffee',
        'copy:styles'
      ],
      dist: [
        'coffee',
      ]
    },
    karma: {
      unit: {
        configFile: 'karma.conf.js',
        singleRun: true
      },
      e2e: {
        configFile: 'karma-e2e.conf.js',
        singleRun: true
      }
    },
    cdnify: {
      dist: {
        html: ['<%= yeoman.dist %>/*.html']
      }
    },
    ngmin: {
      dist: {
        src: ['<%= yeoman.dist %>/nx-websocket.js'],
        dest: '<%= yeoman.dist %>/nx-websocket.ngmin.js'
      }
    },
    uglify: {
      dist: {
        files: {
          '<%= yeoman.dist %>/nx-websocket.min.js': [
            '<%= yeoman.dist %>/nx-websocket.ngmin.js'
          ],
          '<%= yeoman.dist %>/nx-websocket.<%= yeoman.version %>.min.js': [
            '<%= yeoman.dist %>/nx-websocket.ngmin.js'
          ]
        }
      }
    }
  });

  grunt.registerTask('server', function (target) {
    if (target === 'dist') {
      return grunt.task.run(['build', 'open', 'connect:dist:keepalive']);
    }

    grunt.task.run([
      'clean:server',
      'concurrent:server',
      'autoprefixer',
      'connect:livereload',
      'open',
      'watch'
    ]);
  });

  grunt.registerTask('test', [
    'clean:server',
    'concurrent:test',
    'autoprefixer',
    'connect:test',
    'karma'
  ]);
  
  grunt.registerTask('test:unit', [
    'connect:test',
    'karma:unit'
  ]);

  grunt.registerTask('test:e2e', [
    'clean:server',
    'coffee',
    'connect:livereload',
    'karma:e2e'
  ]);

  grunt.registerTask('build', [
    'clean:dist',
    'coffee:dist',
    'jshint',
    'copy:dist',
    'cdnify',
    'ngmin',
    'uglify',
  ]);

  grunt.registerTask('default', [
    'jshint',
    'test',
    'build'
  ]);
};
