#!/usr/bin/python
import Image
import json
import math
import os
import sys
import subprocess
import time
from optparse import OptionParser


"""
	Dependencies:

	brew install ImageMagick

	Python Image Library:

	curl -O -L http://effbot.org/downloads/Imaging-1.1.7.tar.gz
	tar -xzf Imaging-1.1.7.tar.gz
	cd Imaging-1.1.7
	python setup.py build
	python setup.py install

"""

parser = OptionParser()
parser.add_option('-c', '--config', dest = 'config', help = 'The spritesheet config')

(options, args) = parser.parse_args()

CONFIGS  = None
JSON_OUT = 'frames.json' 

with open( options.config ) as f:
	CONFIGS = json.load( f )


if CONFIGS is None:
	sys.exit('Json config is required to generate spritesheet')


#print json.dumps(CONFIGS, sort_keys=True, indent=4)


"""
	Run a sub process

	Parameters:
		cmd -- (String)
"""

def run_process(cmd):
	subprocess.call(cmd.split(' '), shell = False)


"""
	Generates the spritesheets and json for the specific platform

	Parameters:
		id      -- (string)
		config  -- (object)
"""

def exporter(config):

	# Extract settings from the config
	SOURCE_DIR  = config['source']
	TMP_DIR     = SOURCE_DIR + '/../_%s' % str(time.time()).split('.')[0]
	OUTPUT_DIR  = config['output']
	FORMAT      = config['format']
	QUALITY     = config['quality']
	IMAGE_SCALE = config['image_scale']
	TILE_SCALE  = config['tile_scale']
	SPRITESHEET_WIDTH  = config['spritesheet_width']
	SPRITESHEET_HEIGHT = config['spritesheet_height']
	EXTENSIONS  = config['formats']
	KEYFRAMES   = config['keyframes']


	#print SOURCE_DIR, OUTPUT_DIR, IMAGE_SCALE, TILE_SCALE, EXTENSIONS

	print '-----------------------------------------------'
	print "Exporting:: [%s] \n" % SOURCE_DIR

	# Store all source images in this list
	images = [ ]

	# Create directories if it doesn't already exist
	if not os.path.exists(OUTPUT_DIR): os.makedirs(OUTPUT_DIR)
	if not os.path.exists(TMP_DIR): os.makedirs(TMP_DIR)

	cmd = "cp -R ./%s/ %s" % (SOURCE_DIR, TMP_DIR)

	run_process(cmd)

	# Get list of files in source directory
	files      = os.listdir(TMP_DIR)
	length     = len(files)
	num_images = 0
	frame_size = [0, 0]

	for i in range(length):
		file = files[i]
		if file.endswith(FORMAT):
			num_images += 1

			# Get the largest frame size for the spritesheet calculations
			# print file

			_file = '%s/%s' % (TMP_DIR, file)
			img  = Image.open(_file)
			size = img.size # (width, height)

			if size[0] > frame_size[0] : frame_size[0] = size[0]
			if size[1] > frame_size[1] : frame_size[1] = size[1]

			images.append(_file)

	# Scale the frame size
	frame_size[0] *= IMAGE_SCALE
	frame_size[1] *= IMAGE_SCALE


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

	print "Largest frame size: w:%spx h:%spx \n" % (frame_size[0], frame_size[1]) 

	# Calculate the max amount of frames that will fit on a spritesheet
	max_frames_horizontal  = math.floor(SPRITESHEET_WIDTH  / frame_size[0])
	max_frames_vertical    = math.floor(SPRITESHEET_HEIGHT / frame_size[1])
	
	frames_per_spritesheet = int(max_frames_horizontal * max_frames_vertical)

	# The amount of spritesheets to generate
	spritesheets_num = len(files) / float(frames_per_spritesheet)

	if spritesheets_num < 1:
		spritesheets_num = int(math.ceil(spritesheets_num))
	else:
		spritesheets_num = int(round(spritesheets_num))

	print "Frames per spritesheet: %s \n" % frames_per_spritesheet


	frames_data   = []
	images_data   = []
	frames_length = 0
	length        = len(images)
	progress      = 0
	source_images = []


	# for img in _images:
	# 	source_images.append(img + FORMAT)


	# sys.exit('xx')

	for i in range(spritesheets_num):

		index_start = i * frames_per_spritesheet
		index_end   = index_start + frames_per_spritesheet

		# if the end index exceeds the length of the images 
		# change the list selection technique

		if index_end < length:
			spritesheet_images = images[index_start:index_end]
		else:
			spritesheet_images = images[index_start:]

		in_name = ' '.join(spritesheet_images) 

		print in_name

		frames_length += len(spritesheet_images)

		# PNG is generated first for the alpha image mask


		# JPG
		if 'jpg' in EXTENSIONS:

			out_name = OUTPUT_DIR + '/' + "%s.jpg" % i

			cmd = "montage -strip -quality %s -depth 8 %s -tile %sx%s -geometry %sx%s+0+0 -background none -gravity center %s" % (QUALITY, in_name, int(max_frames_horizontal), int(max_frames_vertical), int(frame_size[0]), int(frame_size[1]), out_name)

			run_process(cmd)
		

		# WEBP only if png enabled
		if 'jpg' in EXTENSIONS:

			webp_out_name = OUTPUT_DIR + '/' + "%s.webp" % i

			cmd = "./cwebp %s -o %s -quiet" % (out_name, webp_out_name)

			run_process(cmd)

		progress += 1
		
		print "[%s] --> [%s] Progress %s out of %s" % (TMP_DIR, OUTPUT_DIR, progress, length)

		
	# Create keyframes
	keyframes = dict()

	for key in KEYFRAMES:
		keyframes[key] = KEYFRAMES[key]
	
	print "Saving json..."

	data = dict(type 	     = "spritesheet",
				total_frames = num_images,
				frames_per_spritesheet = frames_per_spritesheet,
				extensions   = EXTENSIONS,
				keyframes    = keyframes,
				frame        = { "width"  : round(frame_size[0]),
								 "height" : round(frame_size[1]),
								 "scale"  : TILE_SCALE
							   }
				)

	with open(OUTPUT_DIR + '/' + JSON_OUT, 'w') as outfile:
		json.dump(data, outfile)


	# Remove tmp dir
	cmd = "rm -rf %s" % TMP_DIR

	run_process(cmd)

	print "Saving complete"


# Run the exporter
for config in CONFIGS['spritesheets']:
	exporter(config)