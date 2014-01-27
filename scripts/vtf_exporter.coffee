###
Video to image sequence exporter

Dependancies:

	node:
		ffmpg
		shjs

	other:
		ffmpeg

###

require 'shelljs/global'
ffmpeg = require 'ffmpeg'

CONFIGS = require './vtf_config.json'
SCRIPT_DIR = pwd()

# src = './test.avi'
exporter = (dir, src, config) ->
	echo dir, config

	echo '--> Export starting'

	try
		cd dir

		# Make the output directory
		mkdir '-p', config.out

		process = new ffmpeg src
		process.then( (video) ->
			echo 'The video is ready to be processed'

			# console.log(video.metadata);
			# FFmpeg configuration
			# console.log(video.info_configuration);

			settings =
				frame_rate: config.frame_rate
				file_name : 'frame_%t_%s'

			video.fnExtractFrameToJPG(config.out, settings, (err, files) ->

				if not error
					console.log 'frames', files

				echo '--> Export complete'

				cd SCRIPT_DIR
			)

		, (err) ->
			echo 'Error: ', err

			cd SCRIPT_DIR
		)

	catch e
		echo 'Error', e.code, e.msg


for config in CONFIGS['videos']
	echo config
	for dir, i in config.dirs
		exporter dir, config.src[i], config