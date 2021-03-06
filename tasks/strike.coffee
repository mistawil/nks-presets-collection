# AIR Music Technology Strike
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - Strike  2.06.18983
# ---------------------------------------------------------------
path     = require 'path'
gulp     = require 'gulp'
tap      = require 'gulp-tap'
extract  = require 'gulp-riff-extractor'
data     = require 'gulp-data'
rename   = require 'gulp-rename'
_        = require 'underscore'
util     = require '../lib/util'
task     = require '../lib/common-tasks'

# buld environment & misc settings
#-------------------------------------------
$ = Object.assign {}, (require '../config'),
  prefix: path.basename __filename, '.coffee'
  
  #  common settings
  # -------------------------
  dir: 'Strike'
  vendor: 'AIR Music Technology'
  magic: 'krtS'
  
  #  local settings
  # -------------------------

  # Ableton Live 9.6.2
  abletonInstrumentRackTemplate: 'src/Strike/templates/Strike-Instrument.adg.tpl'
  abletonDrumRackTemplate: 'src/Strike/templates/Strike-Drum.adg.tpl'
  # Bitwig Studio 1.3.14 RC1 preset file
  bwpresetTemplate: 'src/Strike/templates/Strike.bwpreset'


# preparing tasks
# --------------------------------

# print metadata of _Default.nksf
gulp.task "#{$.prefix}-print-default-meta", ->
  task.print_default_meta $.dir

# print mapping of _Default.nksf
gulp.task "#{$.prefix}-print-default-mapping", ->
  task.print_default_mapping $.dir

# print plugin id of _Default.nksf
gulp.task "#{$.prefix}-print-magic", ->
  task.print_plid $.dir

# generate default mapping file from _Default.nksf
gulp.task "#{$.prefix}-generate-default-mapping", ->
  task.generate_default_mapping $.dir

# extract PCHK chunk from .bwpreset files.
gulp.task "#{$.prefix}-extract-raw-presets", ->
  gulp.src ["temp/#{$.dir}/**/*.nksf"]
    .pipe extract
      chunk_ids: ['PCHK']
    .pipe tap (file) ->
      # fix undesirable recording status
      file.contents[6204] = 0x80
      file.contents[6205] = 0x3f
    .pipe gulp.dest "src/#{$.dir}/presets"

# generate metadata
gulp.task "#{$.prefix}-generate-meta", ->
  presets = "src/#{$.dir}/presets"
  gulp.src ["#{presets}/**/*.pchk"]
    .pipe tap (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, extname
      folder = path.relative presets, path.dirname file.path
      # meta
      file.contents = new Buffer util.beautify
        vendor: $.vendor
        uuid: util.uuid file
        types: for t in folder.split '+'
          ['Drums', t]
        modes: ['Sample Based']
        name: basename
        deviceType: 'INST'
        comment: ''
        bankchain: ['Strike', 'Strike Factory', '']
        author: ''
      , on    # print
    .pipe rename
      extname: '.meta'
    .pipe gulp.dest "src/#{$.dir}/presets"

# generate per preset mappings
gulp.task "#{$.prefix}-generate-mappings", ->
  # read default mapping template
  template = _.template util.readFile "src/#{$.dir}/mappings/default.json.tpl"
  presets = "src/#{$.dir}/presets"
  gulp.src ["#{presets}/**/*.pchk"], read: on
    .pipe tap (file) ->
      # read channel name from plugin-state
      channels = for i in [0..12]
        address = 0x1ec2 + i * 32
        buf = file.contents.slice address, address + 32
        index: i
        name: (buf.toString 'ascii').replace /^([^\u0000]*).*/, '$1'
      channels = channels.filter (channel) -> channel.name
      mapping = JSON.parse template channels: channels
      file.contents = new Buffer util.beautify mapping, on
    .pipe rename
      extname: '.json'
    .pipe gulp.dest "src/#{$.dir}/mappings"

#
# build
# --------------------------------

# copy dist files to dist folder
gulp.task "#{$.prefix}-dist", [
  "#{$.prefix}-dist-image"
  "#{$.prefix}-dist-database"
  "#{$.prefix}-dist-presets"
]

# copy image resources to dist folder
gulp.task "#{$.prefix}-dist-image", ->
  task.dist_image $.dir, $.vendor

# copy database resources to dist folder
gulp.task "#{$.prefix}-dist-database", ->
  task.dist_database $.dir, $.vendor

# build presets file to dist folder
gulp.task "#{$.prefix}-dist-presets", ->
  task.dist_presets $.dir, $.magic, (file) ->
    # per preset mapping file
    "./src/#{$.dir}/mappings/#{file.relative[..-5]}json"

# check
gulp.task "#{$.prefix}-check-dist-presets", ->
  task.check_dist_presets $.dir

#
# deploy
# --------------------------------

gulp.task "#{$.prefix}-deploy", [
  "#{$.prefix}-deploy-resources"
  "#{$.prefix}-deploy-presets"
]

# copy resources to local environment
gulp.task "#{$.prefix}-deploy-resources", [
  "#{$.prefix}-dist-image"
  "#{$.prefix}-dist-database"
], ->
  task.deploy_resources $.dir

# copy database resources to local environment
gulp.task "#{$.prefix}-deploy-presets", [
  "#{$.prefix}-dist-presets"
] , ->
  task.deploy_presets $.dir

#
# release
# --------------------------------

# release zip file to dropbox
gulp.task "#{$.prefix}-release", ["#{$.prefix}-dist"], ->
  task.release $.dir

# export
# --------------------------------

# export from .nksf to .adg ableton instrument and drum rack
gulp.task "#{$.prefix}-export-adg", [
  "#{$.prefix}-export-instrument-adg"
  "#{$.prefix}-export-drum-adg"
]

# export from .nksf to .adg ableton instrument rack
gulp.task "#{$.prefix}-export-instrument-adg", ["#{$.prefix}-dist-presets"], ->
  task.export_adg "dist/#{$.dir}/User Content/#{$.dir}/**/*.nksf"
  , "#{$.Ableton.racks}/#{$.dir}"
  , $.abletonInstrumentRackTemplate

# export from .nksf to .adg ableton drum rack
gulp.task "#{$.prefix}-export-drum-adg", ["#{$.prefix}-dist-presets"], ->
  task.export_adg "dist/#{$.dir}/User Content/#{$.dir}/**/*.nksf"
  , "#{$.Ableton.drumRacks}/#{$.dir}"
  , $.abletonDrumRackTemplate

# export from .nksf to .bwpreset bitwig studio preset
gulp.task "#{$.prefix}-export-bwpreset", ["#{$.prefix}-dist-presets"], ->
  task.export_bwpreset "dist/#{$.dir}/User Content/#{$.dir}/**/*.nksf"
  , "#{$.Bitwig.presets}/#{$.dir}"
  , $.bwpresetTemplate
