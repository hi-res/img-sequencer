#!/usr/bin/python
import Image
import json
import math
import os
import sys
import subprocess
from optparse import OptionParser


"""
Spritesheet generator for chanel moonphase.


Usage:

	Run the command on the image sequence directory.

	`python ss_generator.py --source <source>`

	Adding the `--source-trim` flag will trim the whitespace from the image sequence first


Dependencies:

ImageMagick

Python Image Library:

`
curl -O -L http://effbot.org/downloads/Imaging-1.1.7.tar.gz
tar -xzf Imaging-1.1.7.tar.gz
cd Imaging-1.1.7
python setup.py build
python setup.py install
	`
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

def exporter(id, config):


	# Extract settings from the config
	SOURCE_DIR  = config['source']
	OUTPUT_DIR  = config['output']
	FORMAT      = config['format']
	QUALITY     = config['quality']
	IMAGE_SCALE = config['image_scale']
	TILE_SCALE  = config['tile_scale']
	EXTENSIONS  = config['formats']
	KEYFRAMES   = config['keyframes']

	#print SOURCE_DIR, OUTPUT_DIR, IMAGE_SCALE, TILE_SCALE, EXTENSIONS

	print '-----------------------------------------------'
	print "Exporting:: [%s] \n" % id

	# Store all source images in this list
	images = [ ]

	# Create the output directory if it doesn't already exist
	if not os.path.exists(OUTPUT_DIR): os.makedirs(OUTPUT_DIR)

	# Get list of files in source directory
	files  = os.listdir(SOURCE_DIR)
	
	length  = len(files)
	renamed = False

	# Check source files name, rename if needed
	for i in range(length):

		file = files[i]

		if file.endswith(FORMAT):
			
			name = file.split('.')

			# Don't rename if images are already renamed
			if name[0] == '0':
				renamed = True

			name[0]  = "%s" % i
			new_name = '.'.join(name)

			file_in  = SOURCE_DIR + '/' + file
			file_out = SOURCE_DIR + '/' + new_name

			if renamed is False:
				os.rename(file_in, file_out)

			images.append(file_out)


	# Frame data for json
	images_data = []

	# Counter for progress
	progress = 0

	# Scale and save new images
	length = len(images)

	for i in range(length):

		img = images[i]

		# JPG
		if 'jpg' in EXTENSIONS:

			out_name = OUTPUT_DIR + '/' + "%s.jpg" % i

			cmd  = "convert %s -resize %s%% -depth 6 -quality %s %s" % (img, (IMAGE_SCALE * 100), QUALITY, out_name)

			run_process(cmd)


		# PNG
		if 'png' in EXTENSIONS:

			out_name = OUTPUT_DIR + '/' + "%s.png" % i

			cmd  = "convert %s -resize %s%% -depth 6 -quality %s %s" % (img, (IMAGE_SCALE * 100), QUALITY, out_name)

			run_process(cmd)

			# WEBP only if png enabled
			if 'webp' in EXTENSIONS:

				webp_out_name = OUTPUT_DIR + '/' + "%s.webp" % i

				cmd = "../lib/cwebp %s -o %s -quiet" % (out_name, webp_out_name)

				run_process(cmd)


		progress += 1
		
		print "Progress %s out of %s" % (progress, length)


	# Get the largest frame size for the spritesheet calculations
	frame_size = [0, 0]

	for file in images:

		img  = Image.open(file)
		size = img.size # (width, height)

		if size[0] > frame_size[0] : frame_size[0] = size[0]
		if size[1] > frame_size[1] : frame_size[1] = size[1]

	# Scale the frame size
	frame_size[0] *= IMAGE_SCALE
	frame_size[1] *= IMAGE_SCALE

	# Create keyframes
	keyframes = dict()

	for key in KEYFRAMES:
		keyframes[key] = KEYFRAMES[key]
	
	print "Saving json..."

	data = dict(total_frames = length,
				extensions   = EXTENSIONS,
				keyframes    = keyframes,
				frame        = { "width"  : round(frame_size[0]),
								 "height" : round(frame_size[1]),
								 "scale"  : TILE_SCALE
							   }
				)

	with open(OUTPUT_DIR + '/' + JSON_OUT, 'w') as outfile:
		json.dump(data, outfile)

	print "Saving complete"


# Run the exporter
for config in CONFIGS:
	exporter(config, CONFIGS[config])