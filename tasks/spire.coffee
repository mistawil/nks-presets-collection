# Reveal Sound Spire 1.0.x
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - Spire    (*unknown version)
#  - recycle bitwig presets. https://github.com/jhorology/SpirePack4Bitwig
# ---------------------------------------------------------------
path     = require 'path'
gulp     = require 'gulp'
tap      = require 'gulp-tap'
data     = require 'gulp-data'
rename   = require 'gulp-rename'

util     = require '../lib/util.coffee'
task     = require '../lib/common-tasks'

# buld environment & misc settings
#-------------------------------------------
$ = Object.assign {}, (require '../config.coffee'),
  prefix: path.basename __filename, '.coffee'
  
  #  common settings
  # -------------------------
  dir: 'Spire'
  vendor: 'Reveal Sound'
  magic: 'Spir'

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
  task.extract_raw_presets_from_bw ["#{$.Bitwig.presets}/#{$.dir}/Factory Banks/**/*.bwpreset"], "src/#{$.dir}/presets"

# generate metadata
gulp.task "#{$.prefix}-generate-meta", ->
  presets = "src/#{$.dir}/presets"
  gulp.src ["#{presets}/**/*.pchk"]
    .pipe tap (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, extname
      folder = (path.relative presets, path.dirname file.path).split path.sep
      bank = folder[0]
      type = switch
        when basename[0..3] is 'ATM '  then 'Atmosphere'
        when basename[0..2] is 'AR '   then 'Arpeggiated'
        when basename[0..3] is 'ARP '  then 'Arpeggiated'
        when basename[0..2] is 'BA '   then 'Bass'
        when basename[0..3] is 'BSQ '  then 'Bass Sequence'
        when basename[0..2] is 'CD '   then 'Chord'
        when basename[0..3] is 'CHD '  then 'Chord'
        when basename[0..2] is 'DR '   then 'Drum'
        when basename[0..2] is 'FX '   then 'FX'
        when basename[0..2] is 'GT '   then 'Gated'
        when basename[0..3] is 'KEY '  then 'Keyboard'
        when basename[0..2] is 'LD '   then 'Lead'
        when basename[0..2] is 'LV '   then 'Instrument'
        when basename[0..2] is 'OR '   then 'Organ'
        when basename[0..3] is 'ORG '  then 'Organ'
        when basename[0..2] is 'PD '   then 'Pad'
        when basename[0..2] is 'PA '   then 'Pad'
        when basename[0..2] is 'PL '   then 'Pluck'
        when basename[0..3] is 'STR '  then 'Strings'
        when basename[0..2] is 'SQ '   then 'Sequnce'
        when basename[0..2] is 'SY '   then 'Synth'
        when basename[0..3] is 'VOC '  then 'Vocal'
        when basename[0..4] is 'WIND ' then 'Winds'
        when basename[0..2] is 'SN '   then 'Siren'
        when basename[0..4] is 'Bass ' then 'Bass'
        when basename[0..4] is 'Lead ' then 'Lead'
        when basename[0..4] is 'Chord' then 'Chord'
        when (basename.indexOf ' BS ') > 0  then 'Bass'
        when (basename.indexOf ' LD ') > 0  then 'Lead'
        when (basename.indexOf ' PD ') > 0  then 'Pad'
        when (basename.indexOf ' PL ') > 0  then 'Pluck'
        when basename[-3..] is ' FX'   then 'FX'
        else 'Non-Category'

      author = switch
        when bank is 'Factory Bank 1'   then 'Reveal Sound'
        when bank is 'Factory Bank 5'   then folder[1]
        when basename[-3..] is ' AS'    then 'Adam Szabo'
        when basename[-3..] is ' AZ'    then 'Aiyn Zahev Sounds'
        when basename[-4..] is ' IPM'   then 'Ice Planet Music'
        when basename[-2..] is ' I'     then 'Invader!'
        when basename[-4..] is ' JRM'   then 'Julian Ray'
        when basename[-3..] is ' HJ'    then 'Joseph Hollo'
        when basename[-4..] is ' LUF'   then 'Luftrum'
        when basename[-3..] is ' DP'    then 'Dallaz Project'
        when basename[-4..] is ' BJP'   then 'Braian John Porter'
        when basename[-3..] is ' SK'    then 'Serhiy Klimenkov'
        when basename[-2..] is ' V'     then 'Vullcan'
        when basename[-4..] is ' VTL'   then 'Vi Ta Lee'
        when basename[-4..] is ' MLM'   then 'Mathieu Le Manson'
        when basename[-6..] is ' AL&RS' then 'Alex Larichev & Rusty Spica'
        when basename[-3..] is ' eX'    then 'E.SoX'
        else ''

      file.contents = new Buffer util.beautify
        vendor: $.vendor
        uuid: util.uuid file
        types: [[type]]
        modes: []
        name: basename
        deviceType: 'INST'
        comment: ''
        bankchain: ['Spire', bank, '']
        author: author
      , on    # print
    .pipe rename
      extname: '.meta'
    .pipe gulp.dest "src/#{$.dir}/presets"

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
  task.dist_presets $.dir, $.magic

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
