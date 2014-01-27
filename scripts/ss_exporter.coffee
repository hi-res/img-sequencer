###
Spritesheet and image sequence exporter

Dependancies:

	node:
		shjs

	other:
		imagemagick

	ulimit -n 10000

###

require 'shelljs/global'
_  = require 'lodash'
fs = require 'fs'
sizeOf = require 'image-size'

CONFIGS    = require './ss_config.json'
SCRIPT_DIR = pwd()
WEBP_PATH  = pwd()

exporter = (dir, config, callback) ->

	echo '------------------------------------------------'
	echo "[#{dir}] Export starting"

	cd dir

	# Make the output directory
	mkdir '-p', config.out
	# Create a tmp directory and copy the files
	tmp_dir = '_' + String(Date.now())
	mkdir '-p', tmp_dir

	# Get and sort the images
	cd './' + config.src

	images = []
	for file in ls "*.#{config.format}"

		images.push file
	
	cd '..'

	# sort_files = ( a, b ) ->
	# 	a = Number( a.split('.')[0] )
	# 	b = Number( b.split('.')[0] )
	# 	return a - b

	# images.sort sort_files

	# Copy source files to tmp dir
	cp '-R', "#{config.src}/*", tmp_dir

	# Array of bash commands to execute
	cmds = []

	# Get dimensions of first image
	dimensions = sizeOf tmp_dir + '/' + images[0]

	image_width  = Math.ceil dimensions.width * config.src_scale
	image_height = Math.ceil dimensions.height * config.src_scale
	num_images 	 = images.length

	# echo 'image_width', image_width
	# echo 'image_height', image_height

	data = 
		type:   config.type
		total_frames: num_images
		extensions: config.extensions
		keyframes: config.keyframes
		frame:
			width: image_width
			height: image_height
			scale: config.frame_scale

	# return

	if config.type is 'spritesheet'

		# Calculate the max amount of frames that will fit on a spritesheet
		max_frames_horizontal  = Math.floor(config.spritesheet_width  / image_width)
		max_frames_vertical    = Math.floor(config.spritesheet_height / image_height)
		frames_per_spritesheet = Math.floor(max_frames_horizontal * max_frames_vertical)
		num_spritesheets 	   = Math.ceil(images.length / frames_per_spritesheet)
		
		# echo 'max_frames_horizontal', max_frames_horizontal
		# echo 'max_frames_vertical', max_frames_vertical
		# echo 'frames_per_spritesheet', frames_per_spritesheet
		# echo 'num_spritesheets', num_spritesheets

		for i in [0...num_spritesheets]

			# echo 'amount', amount
			frames = images.splice 0, frames_per_spritesheet

			frames_list = frames.join " #{tmp_dir}/"
			frames_list = "#{tmp_dir}/" + frames_list

			# for frame in frames
			# 	echo frame

			# continue

			for ext in config.extensions

				out_name = config.out + '/' + "#{i}.#{ext}"

				switch ext
					when 'webp'

						out_name_jpg = config.out + '/' + "#{i}.jpg"

						cmds.push "#{WEBP_PATH}/cwebp #{out_name_jpg} -o #{out_name} -quiet"
					else
						cmds.push "montage -strip -quality #{config.quality} -depth 8 #{frames_list} -tile #{max_frames_horizontal}x#{max_frames_vertical} -geometry #{image_width}x#{image_height}+#{config.spacing_x}+#{config.spacing_y} #{out_name}"


		# Add additional spritesheet data
		data.width 					= Math.ceil max_frames_horizontal * image_width
		data.height 				= Math.ceil max_frames_vertical * image_height
		data.total_spritesheets 	= num_spritesheets
		data.frames_per_spritesheet = frames_per_spritesheet

	else

		# Sequence

		for i in [0...num_images]

			img = images[i]

			for ext in config.extensions

				in_name  = tmp_dir + '/' + img
				out_name = config.out + '/' + "#{i}.#{ext}"
				scale = config.src_scale * 100
				
				switch ext
					when 'webp'
						out_name_jpg = config.out + '/' + "#{i}.jpg"

						cmds.push "#{WEBP_PATH}/cwebp #{out_name_jpg} -o #{out_name} -quiet"

					else

						cmds.push "convert #{in_name} -resize #{scale}% -depth 6 -quality #{config.quality} #{out_name}"


	export_json = =>

		# Remove the tmp directory
		rm '-rf', tmp_dir

		frames_json = config.out + '/frames.json'
		
		fs.writeFile frames_json, JSON.stringify(data), (err) ->
			if err
				echo err
				return

		cd SCRIPT_DIR

		echo "[#{dir}] Export complete"

		callback()

	num_cmds = cmds.length

	run = (cmds) =>

		if cmds.length is 0
			export_json()
			return

		echo "[#{dir}] Progress #{num_cmds-cmds.length+1} / #{num_cmds}"

		cmd = cmds.shift()

		exec cmd, (code, output) ->
			# console.log('Exit code:', code);
			# console.log('Program output:', output);
			run cmds

	run cmds


run = (sequences) =>

	if sequences.length is 0
		# Done
		return

	config = sequences.shift()

	exporter config[0], config[1], ->
		run sequences


sequences = []
for config in CONFIGS['sequences']
	for dir in config.dirs
		sequences.push [dir, config]

run sequences