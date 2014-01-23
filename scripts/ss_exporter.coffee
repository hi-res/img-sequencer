###
Spritesheet and image sequence exporter

Dependancies:

	node:
		shjs

	other:
		imagemagick

###

require 'shelljs/global'
_  = require 'lodash'
fs = require 'fs'

CONFIGS    = require './ss_config.json'
SCRIPT_DIR = pwd()
WEBP_PATH  = pwd()

exporter = (dir, config) ->

	echo '--> Export starting'

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

	sort_files = ( a, b ) ->
		a = Number( a.split('.')[0] )
		b = Number( b.split('.')[0] )
		return a - b

	images.sort sort_files

	# Copy source files to tmp dir
	cp '-R', "#{config.src}/*", tmp_dir

	image_width  = config.src_width * config.scale
	image_height = config.src_height * config.scale
	num_images 	 = images.length

	data = 
		type:   config.type
		total_frames: num_images
		extensions: config.extensions
		keyframes: config.keyframes
		frame:
			width: image_width
			height: image_height
			scale: config.scale

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

			for ext in config.extensions

				cmd = ''
				out_name = config.out + '/' + "#{i}.#{ext}"

				switch ext
					when 'webp'

						out_name_jpg = config.out + '/' + "#{i}.jpg"

						cmd = "#{WEBP_PATH}/cwebp #{out_name_jpg} -o #{out_name} -quiet"

					else
						cmd = "montage -strip -quality #{config.quality} -depth 8 #{frames_list} -tile #{max_frames_horizontal}x#{max_frames_vertical} -geometry #{image_width}x#{image_height}+#{config.spacing_x}+#{config.spacing_y} #{out_name}"


				exec cmd

			echo "Progress #{i+1} / #{num_spritesheets}"

		# Add additional spritesheet data
		data.width 					= max_frames_horizontal * image_width
		data.height 				= max_frames_horizontal * image_height
		data.total_spritesheets 	= num_spritesheets
		data.frames_per_spritesheet = frames_per_spritesheet

	else

		# Sequence

		for i in [0...num_images]

			img = images[i]

			for ext in config.extensions

				cmd = ''
				in_name  = tmp_dir + '/' + img
				out_name = config.out + '/' + "#{i}.#{ext}"
				scale = config.scale * 100

				# echo 'in_name', in_name
				# echo 'out_name', out_name
				
				switch ext
					when 'webp'
						out_name_jpg = config.out + '/' + "#{i}.jpg"

						cmd = "#{WEBP_PATH}/cwebp #{out_name_jpg} -o #{out_name} -quiet"

					else

						cmd  = "convert #{in_name} -resize #{scale}% -depth 6 -quality #{config.quality} #{out_name}"

				exec cmd

			echo "Progress #{i+1} / #{num_images}"


	# Remove the tmp directory
	rm '-rf', tmp_dir

	frames_json = config.out + '/frames.json'
	
	fs.writeFile frames_json, JSON.stringify(data), (err) ->
		if err
			echo err
			return

	cd SCRIPT_DIR

	echo '--> Export complete'



for config in CONFIGS['sequences']
	for dir in config.dirs
		exporter dir, config