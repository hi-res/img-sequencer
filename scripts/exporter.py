#!/usr/bin/python
import Image
import json
import math
import os
import sys
import subprocess
import time
from optparse import OptionParser

parser = OptionParser()
parser.add_option('-c', '--config', dest = 'config', help = 'The spritesheet config')
parser.add_option('--cwebppath', dest = 'cwebppath', help = 'The path to the cwebp')

(options, args) = parser.parse_args()

CONFIGS  = None
JSON_OUT = 'frames.json' 

with open( options.config ) as f:
	CONFIGS = json.load( f )


if CONFIGS is None:
	sys.exit('Json config is required to generate spritesheet')


def run_process(cmd):
	subprocess.call(cmd.split(' '), shell = False)

def exporter(sequence, config):

	SOURCE_DIR  = sequence + os.sep + config['source_path']
	TMP_DIR     = sequence + os.sep + ('%s' % str(time.time()).split('.')[0])
	OUTPUT_DIR  = sequence + os.sep + config['output_path'] + os.sep + config['output_dir']
	FORMAT      = config['format']
	QUALITY     = config['quality']
	IMAGE_SCALE = config['image_scale']
	TILE_SCALE  = config['tile_scale']
	EXTENSIONS  = config['formats']
	KEYFRAMES   = config['keyframes']

	#print SOURCE_DIR, OUTPUT_DIR, IMAGE_SCALE, TILE_SCALE, EXTENSIONS

	print '-----------------------------------------------'
	print "Exporting:: [%s] \n" % SOURCE_DIR

	# Store all source images in this list
	images = [ ]

	# Clear the output directory and remake
	if os.path.exists(OUTPUT_DIR): 

		cmd = "rm -rf %s" % OUTPUT_DIR
		run_process(cmd) 

		os.makedirs(OUTPUT_DIR)
	
	if not os.path.exists(TMP_DIR): os.makedirs(TMP_DIR)
	if not os.path.exists(OUTPUT_DIR): os.makedirs(OUTPUT_DIR)

	# Copy the source images 
	cmd = "cp -R %s%s %s" % (SOURCE_DIR, os.sep, TMP_DIR)
	run_process(cmd)

	# Get list of files in source directory
	files      = os.listdir(TMP_DIR)
	length     = len(files)
	num_images = 0

	tmp = []
	for i in range(length):
		file = files[i]
		if file.endswith(FORMAT):
			num_images += 1
			tmp.append(file)

	files = tmp

	# Rename images
	for i in range(num_images):

		file_in  = os.getcwd() + os.sep + TMP_DIR + os.sep + '%s' % files[i]
		file_out = os.getcwd() + os.sep + TMP_DIR + os.sep + '%s.%s' % (i, FORMAT)

		# print file_in, file_out
		os.rename(file_in, file_out)

		images.append(file_out)


	# Make sure the src and output dir are writeable
	cmd = "chmod -R 777 %s" % TMP_DIR
	run_process(cmd)
	cmd = "chmod -R 777 %s" % OUTPUT_DIR
	run_process(cmd)

	# Frame data for json
	images_data = []

	# Counter for progress
	progress = 0

	# Scale and save new images
	length = len(images)

	# print images

	for i in range(length):

		img = images[i]

		# JPG
		if 'jpg' in EXTENSIONS:

			out_name = OUTPUT_DIR + os.sep + "%s.jpg" % i

			cmd  = "convert %s -resize %s%% -depth 6 -quality %s %s" % (img, (IMAGE_SCALE * 100), QUALITY, out_name)

			run_process(cmd)


		# PNG
		if 'png' in EXTENSIONS:

			out_name = OUTPUT_DIR + os.sep + "%s.png" % i

			cmd  = "convert %s -resize %s%% -depth 6 -quality %s %s" % (img, (IMAGE_SCALE * 100), QUALITY, out_name)

			run_process(cmd)


		# WEBP only if png enabled
		if 'webp' in EXTENSIONS:

			# Create png for webp conversion

			out_name = OUTPUT_DIR + os.sep + "%s.png" % i

			try:
				with open(out_name):
					pass

			except IOError:

				cmd  = "convert %s -resize %s%% -depth 6 -quality %s %s" % (img, (IMAGE_SCALE * 100), QUALITY, out_name)

				run_process(cmd)

			webp_out_name = OUTPUT_DIR + os.sep + "%s.webp" % i

			cmd = "%scwebp %s -o %s -quiet" % (options.cwebppath, out_name, webp_out_name)

			run_process(cmd)

			# Remove tmp png
			if 'png' not in EXTENSIONS:
				try:
					cmd = "rm %s" % out_name
					run_process(cmd)
				except IOError:
					pass

		progress += 1
		
		print "[%s] --> [%s] Progress %s out of %s" % (TMP_DIR, OUTPUT_DIR, progress, length)

	# Get the image size
	frame_size = [0, 0]

	img  = Image.open(images[0])
	size = img.size # (width, height)

	frame_size[0] = size[0] * IMAGE_SCALE
	frame_size[1] = size[1] * IMAGE_SCALE

	# Create keyframes
	keyframes = dict()

	for key in KEYFRAMES:
		keyframes[key] = KEYFRAMES[key]
	
	print "Saving json..."

	data = dict(total_frames = num_images,
				extensions   = EXTENSIONS,
				keyframes    = keyframes,
				frame        = { "width"  : round(frame_size[0]),
								 "height" : round(frame_size[1]),
								 "scale"  : TILE_SCALE
							   }
				)

	with open(OUTPUT_DIR + os.sep + JSON_OUT, 'w') as outfile:
		json.dump(data, outfile)


	# Remove tmp dir
	cmd = "rm -rf %s" % TMP_DIR
	run_process(cmd)

	print "Saving complete"


# Run the exporter
for config in CONFIGS['export_sequences']:
	for sequence in config['sequences']:
		exporter(sequence, config)