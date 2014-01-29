Sequencer = Sequencer or {}

Sequencer.util = 

	calculate_resize: (image_width, image_height, win_width, win_height) ->

		window_ratio = win_width / win_height
		image_ratio1 = image_width / image_height
		image_ratio2 = image_height / image_width

		if window_ratio < image_ratio1
			
			new_height = win_height
			new_width  = Math.round( new_height * image_ratio1 )

			new_top  = 0
			new_left = (win_width * .5) - (new_width * .5) 

		else
			
			new_width  = win_width
			new_height = Math.round( new_width * image_ratio2 );

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

		data = @calculate_resize image_width, image_height, win_width, win_height

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


	resize_spritesheet: ($images, image_width, image_height, win_width, win_height, max_frames_horizontal, max_frames_vertical) ->

		# console.log 'image_width', image_width, 'image_height',image_height 

		data = @calculate_resize image_width, image_height, win_width, win_height

		# Background size is a lot fast than scaling and positioning an image

		size_x = data.width * max_frames_horizontal
		size_y = data.height * max_frames_vertical

		$images.css
			'background-size' : "#{size_x}px #{size_y}px"

		return [data.width, data.height, data.x, data.y]
