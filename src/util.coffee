Sequencer = Sequencer or {}

Sequencer.util = 

	calculate_resize: (image_width, image_height, win_width, win_height, backgroundsize) ->

		window_ratio = win_width / win_height
		image_ratio1 = image_width / image_height
		image_ratio2 = image_height / image_width

		if window_ratio < image_ratio1
			# log 'portrait'
			new_height = win_height
			new_width  = new_height * image_ratio1

			new_top  = 0
			new_left = (win_width * .5) - (new_width * .5) 

		else
			# log 'landscape'
			new_width  = win_width
			new_height = new_width * image_ratio2

			new_top  = (win_height * .5) - (new_height * .5)
			new_left = 0 

		return {
			x      : new_left
			y      : new_top
			width  : new_width
			height : new_height
		}

	###
	Resize image(s) to the browser size retaining aspect ratio
	@param [jQuery]  $images
	@param [Number]  image_width
	@param [Number]  image_height
	@param [Number]  win_width
	@param [Number]  win_width
	@param [Boolean] backgroundsize
	###
	resize: ($images, image_width, image_height, win_width, win_height, backgroundsize) ->

		data = @calculate_resize image_width, image_height, win_width, win_height, backgroundsize

		# Background size is a lot fast than scaling and positioning an image

		if backgroundsize
			$images.css
				'background-size'     : "#{data.width}px #{data.height}px"
				'background-position' : "#{data.x}px #{data.y}px"
		else
			$images.css
				'margin-top'  : "#{data.y}px"
				'margin-left' : "#{data.x}px"
				'width'       : "#{data.width}px"
				'height'      : "#{data.height}px"