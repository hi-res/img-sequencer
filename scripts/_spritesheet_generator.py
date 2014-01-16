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

		Python Image Library:
		
		`
		curl -O -L http://effbot.org/downloads/Imaging-1.1.7.tar.gz
		tar -xzf Imaging-1.1.7.tar.gz
		cd Imaging-1.1.7
		python setup.py build
		sudo python setup.py install
		`

"""

# Command line parser

parser = OptionParser()
parser.add_option('-c', '--config', dest = 'config', help = 'The spritesheet config', default = '')
parser.add_option('-s', '--source', dest = 'source_directory', help = 'The image sequence source directory', default = '')
parser.add_option('-f', '--source-format', dest = 'source_format', help = 'The image source format', default = 'png')
parser.add_option('-t', '--source-trim', dest = 'source_trim', help = 'Remove the alpha whitespace from the image source', default = False)
parser.add_option('-q', '--quality', dest = 'quality', help = 'An image compression percentage from 0-100 for the final spritesheet', default = 70)

(options, args) = parser.parse_args()


# Defaults

"""
The spritesheet generator configs are structured in a tuple with the following data properties:

	width            -- (int)    the width of the spritesheet
	height           -- (int)    the height of the spritesheet
	image scale      -- (float)  how much to scale the image down too
	tile scale       -- (float)  a normalise ratio to match the original tile size
	output directory -- (string) the output directory name
	formats          -- (tuple)  image output formats

"""

CONFIGS = None

with open( options.config ) as f:
	CONFIGS = json.load( f )


if CONFIGS is None:
	sys.exit('Json config is required to generate spritesheet')


CONFIGS      = CONFIGS['configs']

TRIM         = options.source_trim # Set once if the --source-trim flag is set to true

SS_JSON      = 'scene.json' 

ALPHA_PREFIX = 'a'


"""
	Run a sub process

	Parameters:

		cmd -- (String) A command string to evaluate
"""

def run_process(cmd):
	subprocess.call(cmd.split(' '), shell = False)


"""
	Generates the spritesheets and json for the specific platform

	Parameters:

		config  -- (tuple) A configuration tuple
"""

def spritesheet_generator(config):

	# Extract settings from the config
	spritesheet_width            = config['width']
	spritesheet_height           = config['height']
	spritesheet_image_scale      = config['image_scale']
	spritesheet_tile_scale       = config['tile_scale']
	spritesheet_frames_per_cache = config['frames_per_cache']
	spritesheet_dir              = config['output_directory']
	spritesheet_extensions       = config['formats']

	print '-----------------------------------------------'
	print "spritesheet_generator:: [%s] \n" % spritesheet_dir

	# Store all source images in this list
	images = [ ]

	# Output directory path
	output_directory = options.source_directory.split('/')
	output_directory[-1] = spritesheet_dir + '/'
	output_directory = '/'.join(output_directory)

	# Create the output directory if it doesn't already exist
	if not os.path.exists(output_directory): os.makedirs(output_directory)

	# Counter for progress
	progress = 0

	# Check source files name, rename if needed

	files  = os.listdir(options.source_directory)
	length = len(files)
	prefix = "0"

	for i in range(length):

		file = files[i]

		if file.endswith(options.source_format):
			
			if i > 9:
				prefix = ""

			name     = file.split('.')
			name[0]  = "%s%s" % (prefix, i)
			
			new_name = '.'.join(name)

			file_in  = options.source_directory + '/' + file
			file_out = options.source_directory + '/' + new_name
			
			#print file_in, file_out
			os.rename(file_in, file_out)

			images.append(file_out)

	#print images

	#sys.exit('xxx')

	# Trim alpha whitespace

	global TRIM

	if TRIM:

		print "Trimming whitespace \n"

		length = len(images)

		for file in images:

			cmd = "convert %s -trim +repage %s" % (file, file)

			run_process(cmd)

			progress += 1
			
			print "progress %s out of %s" % (progress, length)

		print "Trimming complete \n" 

		# Disable the trim from running again

		TRIM = False


	# Get the largest frame size for the spritesheet calculations

	frame_size = [0, 0]

	for file in images:

		img  = Image.open(file)
		size = img.size # (width, height)

		if size[0] > frame_size[0] : frame_size[0] = size[0]
		if size[1] > frame_size[1] : frame_size[1] = size[1]


	# Scale the frame size
	frame_size[0] *= spritesheet_image_scale
	frame_size[1] *= spritesheet_image_scale

	print "Largest frame size: w:%spx h:%spx \n" % (frame_size[0], frame_size[1]) 

	# Calculate the max amount of frames that will fit on a spritesheet
	max_frames_horizontal  = math.floor(spritesheet_width  / frame_size[0])
	max_frames_vertical    = math.floor(spritesheet_height / frame_size[1])
	
	frames_per_spritesheet = int(max_frames_horizontal * max_frames_vertical)

	# The amount of spritesheets to generate
	spritesheets_num = len(files) / float(frames_per_spritesheet)

	if spritesheets_num < 1:
		spritesheets_num = int(math.ceil(spritesheets_num))
	else:
		spritesheets_num = int(round(spritesheets_num))

	print "Frames per spritesheet: %s \n" % frames_per_spritesheet

	# Generate the spritesheet images

	print "Generating %s spritesheets... \n" % spritesheets_num

	frames_data   = []
	images_data   = []
	frames_length = 0
	length        = len(images)
	progress      = 0

	for i in range(spritesheets_num):

		index_start = i * frames_per_spritesheet
		index_end   = index_start + frames_per_spritesheet

		# if the end index exceeds the length of the images 
		# change the list selection technique

		if index_end < length:
			spritesheet_images = images[index_start:index_end]
		else:
			spritesheet_images = images[index_start:]

		in_name  =  ' '.join(spritesheet_images)

		frames_length += len(spritesheet_images)


		# PNG is generated first for the alpha image mask

		out_name       =  "%s.png" % i
		out_alpha_name =  "%s%s.png" % (i, ALPHA_PREFIX)

		cmd = "montage -strip -quality %s -depth 8 %s -tile %sx%s -geometry %sx%s+0+0 -background none -gravity center %s" % (options.quality, in_name, int(max_frames_horizontal), int(max_frames_vertical), int(frame_size[0]), int(frame_size[1]), output_directory + out_name)

		run_process(cmd)

		# Alpha mask 

		cmd = "convert %s -alpha off -fill black -colorize 100%% -alpha on %s" % (output_directory + out_name, output_directory + out_alpha_name)

		run_process(cmd)


		if 'webp' in spritesheet_extensions:

			# webp

			webp_out_name = "%s.webp" % i

			cmd = "sudo cwebp %s -o %s" % (output_directory + out_name, output_directory + webp_out_name)

			run_process(cmd)
			

		if 'jpg' in spritesheet_extensions:
		
			# jpg, other types

			out_name =  "%s.jpg" % i
			cmd = "montage -strip -quality %s %s -tile %sx%s -geometry %sx%s+0+0 -background white -gravity center %s" % (options.quality, in_name, int(max_frames_horizontal), int(max_frames_vertical), int(frame_size[0]), int(frame_size[1]), output_directory + out_name)
			
			run_process(cmd)


		# Get image dimension

		img  = Image.open(output_directory + out_name)
		size = img.size # (width, height)

		# Add data for json output

		images_data.append({
			"file": dict( image = "%s" % i, alpha = "%s%s" % (i, ALPHA_PREFIX) ),
			"size": size
		})


		# Delete the png if it's not defined in spritesheet_extensions

		if 'png' not in spritesheet_extensions:

			cmd = "rm %s" %  output_directory + "%s.png" % i
			run_process(cmd)


		progress += 1

		print "Spritesheets progress %s out of %s \n" % (progress, spritesheets_num)



	# Save spritesheet data to json

	print "Spritesheets generated \n"

	print "Saving json..."

	data = dict(total_frames = frames_length,
				frames_per_cache = spritesheet_frames_per_cache,
				files        = images_data, 
				file_types   = spritesheet_extensions,
				tile         = { "width"  : int(frame_size[0]),
							     "height" : int(frame_size[1])
							   },
				tile_scale   = spritesheet_tile_scale,
				alpha_prefix = ALPHA_PREFIX
				)

	out_json = output_directory + SS_JSON

	with open(out_json, 'w') as outfile:
		json.dump(data, outfile)

	print "Saving complete \n"



# Run the generator

if options.source_directory is '':
	sys.exit('You need to specify a source directory')

for config in CONFIGS:
	spritesheet_generator(config)