extends TileMap

# Puzzle Game Using Tilemap Custom Layers

@onready var scoreTexture: Resource = preload("res://content/assets/png/score_sprite.png")
@onready var slot_1: TextureRect = $"../LevelControl/NextPieceControl/CenterContainer/GridContainer/CenterContainer/slot_1"
@onready var slot_2: TextureRect = $"../LevelControl/NextPieceControl/CenterContainer/GridContainer/CenterContainer2/slot_2"
@onready var slot_3: TextureRect = $"../LevelControl/NextPieceControl/CenterContainer/GridContainer/CenterContainer3/slot_3"
@onready var slot_4: TextureRect = $"../LevelControl/NextPieceControl/CenterContainer/GridContainer/CenterContainer4/slot_4"
@onready var slot_5: TextureRect = $"../LevelControl/NextPieceControl/CenterContainer/GridContainer/CenterContainer5/slot_5"
@onready var slot_6: TextureRect = $"../LevelControl/NextPieceControl/CenterContainer/GridContainer/CenterContainer6/slot_6"
@onready var tileMatchingDict: Dictionary = {}
@onready var saveLocation: String = "user://PuzzleSave/"
@onready var saveFile: String = "PuzzleBestScore.txt"

# Check for available move spaces in player swap
var availableTileSpaces: Array = [
Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2), Vector2i(5, 2), Vector2i(6, 2), 
Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 3), Vector2i(5, 3), Vector2i(6, 3), 
Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4), Vector2i(4, 4), Vector2i(5, 4), Vector2i(6, 4), 
Vector2i(1, 5), Vector2i(2, 5), Vector2i(3, 5), Vector2i(4, 5), Vector2i(5, 5), Vector2i(6, 5), 
Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6), Vector2i(4, 6), Vector2i(5, 6), Vector2i(6, 6), 
Vector2i(1, 7), Vector2i(2, 7), Vector2i(3, 7), Vector2i(4, 7), Vector2i(5, 7), Vector2i(6, 7), 
Vector2i(1, 8), Vector2i(2, 8), Vector2i(3, 8), Vector2i(4, 8), Vector2i(5, 8), Vector2i(6, 8), 
Vector2i(1, 9), Vector2i(2, 9), Vector2i(3, 9), Vector2i(4, 9), Vector2i(5, 9), Vector2i(6, 9), 
]

var saveDict: Dictionary = {}
var bestScore: int = 0
var score: int = 0
var columns: int = 6 # No need for offset here because x start at 1
var rows: int = 8 # Using an offset for y from grid 0,0 in function
var swapStart: Vector2i = Vector2i.ZERO # Keep track in case swap didn't produce match
var swapEnd: Vector2i = Vector2i.ZERO # Keep track in case swap didn't produce match
var swapTileFrom: int = 0 # Based on source ID
var swapTileTo: int = 0 # Based on source ID
var canSwap: bool = false # Checked in tilemap_swap_pieces()
var checkMove: bool = true # Used when player moves to create animations
var grabbedPiece: bool = false
var sound: bool = true
var music: bool = true
var lockedIndex: int = -1
var modulatedColorArray: Array = [Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW, Color.PINK]
var newSlot_1Color: int = 0
var newSlot_2Color: int = 0
var newSlot_3Color: int = 0
var newSlot_4Color: int = 0
var newSlot_5Color: int = 0
var newSlot_6Color: int = 0
var colorArray: Array = []

#
# Make sure you set the ui_pause in project settings
# under input map tab, and in the add new action text box.
# If you're not sure how, consider looking at a previous
# tutorial I made on the game setup.
#
 
func _ready():
	colorArray = [Color(0.62, 0.208, 0.208, 0.8), Color(0.255, 0.694, 0.255, 0.8), Color(0.353, 0.31, 0.714, 0.8), Color(0.945, 1, 0.592, 0.8), Color(0.796, 0.467, 1, 0.8)]
	if OS.has_feature("editor"):
		saveLocation = "res://save_folder/"
	load_save_file(saveLocation)
	$"../LevelControl/BorderControl/TopBorder/ScoreLabel/Amount".text = str(score)
	# Pick a random color here for the new sprites
	newSlot_1Color = randi_range(0, 4)
	newSlot_2Color = randi_range(0, 4)
	newSlot_3Color = randi_range(0, 4)
	newSlot_4Color = randi_range(0, 4)
	newSlot_5Color = randi_range(0, 4)
	newSlot_6Color = randi_range(0, 4)
	
	# Set the color here before the game starts. 
	slot_1.modulate = colorArray[newSlot_1Color]
	slot_2.modulate = colorArray[newSlot_2Color]
	slot_3.modulate = colorArray[newSlot_3Color]
	slot_4.modulate = colorArray[newSlot_4Color]
	slot_5.modulate = colorArray[newSlot_5Color]
	slot_6.modulate = colorArray[newSlot_6Color]
	#for i in availableTileSpaces:
		## Initial random filling of the tilemap
		#set_cell(0, i, randi_range(0,4), Vector2i(0, 0))
	
	tilemap_check_all_data()
	# The await is only to see the loding text 
	# and give the game enough time to check all
	# the tiles from tilemap_check_all_data()
	await get_tree().create_timer(1.0).timeout
	$"../LoadingNode/LoadingControl/ReadyButton".show()
	$"../LoadingNode/LoadingControl/LoadingLabel".hide()
	

# Called by connecting the ready button(signal "pressed")
# to this script choosing to pick this function for 
# the signal.
func start_game():
	$"../LoadingNode/LoadingControl".hide()
	# Let them see the board before you determine
	# if there are any tiles to animate.
	await get_tree().create_timer(1.0).timeout
	tilemap_animate_cells()
	

func _unhandled_input(event):
	if Input.is_action_pressed("ui_pause"):
		get_tree().paused = true
		$"../LoadingNode/PauseControl".show()
	if checkMove:
		return
	if event is InputEventScreenTouch and event.pressed:
		print(local_to_map(event.position))
		if get_cell_tile_data(0, local_to_map(event.position)):
			if lockedIndex == -1:
				lockedIndex = event.index
				grabbedPiece = true
				swapEnd = local_to_map(event.position)
				swapStart = local_to_map(event.position)
				swapTileFrom = get_cell_source_id(0, local_to_map(event.position))
				$"../AnimatingControl".get_child(availableTileSpaces.find(swapStart)).modulate = modulatedColorArray[swapTileFrom]
				$"../AnimatingControl".get_child(availableTileSpaces.find(swapStart)).show()
	elif event is InputEventScreenTouch and !event.pressed:
		if grabbedPiece:
			drop_swap_pieces()
		lockedIndex = -1
		grabbedPiece = false
	if event is InputEventScreenDrag:
		if event.index == lockedIndex:
			tilemap_swap_pieces(event.position)
	

# Called with input, so it will process
# when player swaps pieces
func tilemap_swap_pieces(swapTo: Vector2):
	if !checkMove:
		var makeSwapLocal: Vector2i = local_to_map(swapTo)
		# We want to limit the moves to up, down, left, right
		# so making a quick array here with some default variables
		# makes it quick and easy, plus new every time.
		var swapDirArray: Array = [
			(Vector2i.LEFT + swapStart), (Vector2i.RIGHT + swapStart), 
			(Vector2i.UP + swapStart), (Vector2i.DOWN + swapStart)
			]
		for i in swapDirArray:
			if availableTileSpaces.has(i):
				# First, just hiding the sprite here for
				# the quick changes from input
				$"../AnimatingControl".get_child(availableTileSpaces.find(i)).hide()
				# This is where we highlight the selected sprites.
				if makeSwapLocal == i:
					if !makeSwapLocal == swapEnd and sound:
						$"../TileMoveSound".play()
					var sourceID: int = get_cell_source_id(0, makeSwapLocal)
					var swapToSprite: AnimatedSprite2D = $"../AnimatingControl".get_child(availableTileSpaces.find(makeSwapLocal))
					var swapFromSprite: AnimatedSprite2D = $"../AnimatingControl".get_child(availableTileSpaces.find(swapStart))
					swapToSprite.modulate = modulatedColorArray[swapTileFrom]
					swapToSprite.show()
					swapFromSprite.modulate = modulatedColorArray[sourceID]
					swapFromSprite.show()
					# Be sure to set the end pos here
					# it gets reset after the move is
					# checked.
					swapEnd = i
					match sourceID:
						0:
							canSwap = true
							swapTileTo = 0
						1:
							canSwap = true
							swapTileTo = 1
						2:
							canSwap = true
							swapTileTo = 2
						3:
							canSwap = true
							swapTileTo = 3
						4:
							canSwap = true
							swapTileTo = 4
					# Be sure to jump out of function here
					# because we found a valid tile.
					# If no valid tile is found we just keep
					# canSwap false
					return
	canSwap = false
	

# Finally we animate the score nodes and when 
# it is finished, we'll add the score and then
# show the updated score.
func animate_score(scoredPos: Vector2i):
	var scoreSprite: Sprite2D = Sprite2D.new()
	add_child(scoreSprite)
	scoreSprite.z_index = 30
	scoreSprite.texture = scoreTexture
	scoreSprite.modulate = $"../AnimatingControl".get_child(availableTileSpaces.find(scoredPos)).modulate
	scoreSprite.global_position = map_to_local(scoredPos)
	move_score_sprite(scoreSprite)
	# We can create a loop tween, that could handle this
	# differently, but I prefer to divide the animation 
	# like this.
	

func move_score_sprite(spriteToMove: Sprite2D):
	var moveTween: Tween = create_tween()
	var scaleTween: Tween = create_tween()
	var distanceTime: float = (spriteToMove.global_position).distance_to(map_to_local(Vector2i(2, 0)))/500
	if distanceTime < 0.5:
		distanceTime = 0.5
	moveTween.tween_property(spriteToMove, "global_position", map_to_local(Vector2i(2, 0)), distanceTime)
	scaleTween.tween_property(spriteToMove, "scale", Vector2(0.5, 0.5), distanceTime)
	moveTween.tween_callback(Callable(self, "delete_score_sprite").bind(spriteToMove))
	

func delete_score_sprite(usedSprite: Sprite2D):
	usedSprite.call_deferred("queue_free")
	score += 10
	if sound:
		$"../ScoreSound".play()
	if score > bestScore:
		bestScore = score
		$"../LevelControl/BorderControl/TopBorder/ScoreLabel/Amount".add_theme_color_override("font_color", Color.GREEN)
	$"../LevelControl/BorderControl/TopBorder/ScoreLabel/Amount".text = str(score)
	

func request_new_tiles():
	# New slot color array is used to store the 
	# old colors. If any change happens, we 
	# want to the changes to happen together and
	# after our animation is complete. Otherwise, 
	# we just set the color the same with no harm.
	var newSlotColorArray: Array = ["This is place holder for 0 x", newSlot_1Color, newSlot_2Color, newSlot_3Color, newSlot_4Color, newSlot_5Color, newSlot_6Color]
	var emptyRowArray: Array = []
	for i in availableTileSpaces:
		if !get_cell_tile_data(0, i):
			if !emptyRowArray.has(i.x):
				emptyRowArray.append(i.x)
	if emptyRowArray.size()> 0:
		# Randomise the new color and set the new color 
		# on the sprite after we set the animation 
		# tweens to run, with under the amount of time
		# for our await. We can use a tween for a timer,
		# but in this case await is better alone unless 
		# want to create other animations.
		for i in emptyRowArray:
			match i:
				1:
					var slotAnimTween: Tween = create_tween()
					newSlot_1Color = randi_range(0, 4)
					slotAnimTween.tween_property(slot_1, "custom_minimum_size", Vector2(64, 64), 0.3)
				2:
					var slotAnimTween: Tween = create_tween()
					newSlot_2Color = randi_range(0, 4)
					slotAnimTween.tween_property(slot_2, "custom_minimum_size", Vector2(64, 64), 0.3)
				3:
					var slotAnimTween: Tween = create_tween()
					newSlot_3Color = randi_range(0, 4)
					slotAnimTween.tween_property(slot_3, "custom_minimum_size", Vector2(64, 64), 0.3)
				4:
					var slotAnimTween: Tween = create_tween()
					newSlot_4Color = randi_range(0, 4)
					slotAnimTween.tween_property(slot_4, "custom_minimum_size", Vector2(64, 64), 0.3)
				5:
					var slotAnimTween: Tween = create_tween()
					newSlot_5Color = randi_range(0, 4)
					slotAnimTween.tween_property(slot_5, "custom_minimum_size", Vector2(64, 64), 0.3)
				6:
					var slotAnimTween: Tween = create_tween()
					newSlot_6Color = randi_range(0, 4)
					slotAnimTween.tween_property(slot_6, "custom_minimum_size", Vector2(64, 64), 0.3)
		# Making sure we make this timer respond to a paused game
		# set_process_mode(1). Without this timer, the animation 
		# of tile drops from requesting tiles.
		var tweenTimer: Tween = create_tween()
		tweenTimer.tween_interval(0.5)
		await tweenTimer.finished
		slot_1.modulate = colorArray[newSlot_1Color]
		slot_2.modulate = colorArray[newSlot_2Color]
		slot_3.modulate = colorArray[newSlot_3Color]
		slot_4.modulate = colorArray[newSlot_4Color]
		slot_5.modulate = colorArray[newSlot_5Color]
		slot_6.modulate = colorArray[newSlot_6Color]
		slot_1.custom_minimum_size = Vector2(48, 48)
		slot_2.custom_minimum_size = Vector2(48, 48)
		slot_3.custom_minimum_size = Vector2(48, 48)
		slot_4.custom_minimum_size = Vector2(48, 48)
		slot_5.custom_minimum_size = Vector2(48, 48)
		slot_6.custom_minimum_size = Vector2(48, 48)
		for i in emptyRowArray:
			# Add the tiles first, then move the whole
			# tiles to available spaces.
			set_cell(0, Vector2i(i, 2), newSlotColorArray[i], Vector2i(0,0))
		tilemap_move_cells()
	else:
		# Here we will do a full level check after
		# all empty spaces have been filled. You can 
		# do it each time the tiles move... but probably
		# not desired. Matching tiles while in the fall
		# could happen.
		tilemap_check_all_data()
		tilemap_animate_cells()
	

# Called to remove the matching tiles
# and start fall animation. The return
# value is linked to the tile drop.
# If it returns false, means that the 
# drops did not produce any valid matches.
func tilemap_animate_cells()->bool:
	var matchingPieceTotal: int = 0
	# The dictionary stays consistant once you make it.
	# So as long as we call the check all tile data, we'll
	# get a continous update of available tiles.
	for key in tileMatchingDict:
		var matchingTilesArray: Array = []
		for tile in tileMatchingDict[key]:
			# Notice the check on the values. We don't
			# have to worry about a valid tile check here either
			# because we're using the updated information from 
			# the tilemap.
			if tileMatchingDict[key].has(tile+Vector2i.LEFT) and tileMatchingDict[key].has(tile + Vector2i.RIGHT):
				# Check that it's not already in there, you can add 
				# the same value twice to an array.
				if !matchingTilesArray.has(tile+Vector2i.LEFT):
					matchingTilesArray.append(tile+Vector2i.LEFT)
				if !matchingTilesArray.has(tile+Vector2i.RIGHT):
					matchingTilesArray.append(tile+Vector2i.RIGHT)
				if !matchingTilesArray.has(tile):
					matchingTilesArray.append(tile)
			if tileMatchingDict[key].has(tile+Vector2i.UP) and tileMatchingDict[key].has(tile + Vector2i.DOWN):
				if !matchingTilesArray.has(tile+Vector2i.UP):
					matchingTilesArray.append(tile+Vector2i.UP)
				if !matchingTilesArray.has(tile+Vector2i.DOWN):
					matchingTilesArray.append(tile+Vector2i.DOWN)
				if !matchingTilesArray.has(tile):
					matchingTilesArray.append(tile)
		for i in matchingTilesArray:
			# This is another reason the available tile spaces array is important.
			# Using the array, we can match the child node of a node to a position in the array
			# which we took meticulous measures to set each one representative of a square in 
			# the tile map grid.
			
			var animSprite: AnimatedSprite2D = $"../AnimatingControl".get_child(availableTileSpaces.find(i))
			var spriteTweenFrames: Tween = create_tween()
			set_cell(0, i, -1)
			animSprite.animation = "Sad"
			animSprite.show()
			spriteTweenFrames.tween_property(animSprite, "frame", 7, 0.5)
			spriteTweenFrames.tween_callback(Callable(self, "pop_sprite").bind(animSprite))
			matchingPieceTotal += 1
		
	if matchingPieceTotal > 0 or get_used_cells(0).size() < 48:
		# The timer is only used for drop simulation
		var timerTween: Tween = create_tween()
		timerTween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
		timerTween.tween_interval(0.75)
		timerTween.tween_callback(tilemap_move_cells)
	elif matchingPieceTotal == 0:
		checkMove = false
		return false
	return true
	

# Another Tween called function for animating the tile
# detruction.
func pop_sprite(spriteToPop: AnimatedSprite2D):
	var spriteFinishAnimTween: Tween = create_tween()
	spriteToPop.animation = "Pop"
	spriteFinishAnimTween.tween_property(spriteToPop, "frame", 6, 0.2)
	spriteFinishAnimTween.tween_callback(Callable(self, "hide_sprite").bind(spriteToPop))
	

# Since we're not really destroying anything,
# just hide the node for later use. Also, if 
# you wanted to have animations reset or positions
# from tween moving, you can do it here.
func hide_sprite(spriteToHide: AnimatedSprite2D):
	if sound:
		$"../PopSound".play()
	spriteToHide.hide()
	spriteToHide.play("Happy")
	animate_score(local_to_map(spriteToHide.global_position))
	# something like spriteToHide.position = 
	# it might be desirable then to pass other binds in.
	# bind( spriteToHide, spriteToHide.old_position,)
	

# Match tiles and place them in
# tileMatchingDict. Everytime this is called
# it makes a new dictionary with values of tiles
# with data. Old data of tiles non-exsitant still
# persist, because they will be reset when full.
# The tilemap animate cells takes care of checking
# against null tiles because it has to anyways 
# to make sure animations are complete and new tiles
# are called in.
func tilemap_check_all_data():
	var xCount: int = 1 # no need to offset x
	var yCount: int = 2 # offset
	var allRedArray: Array = []
	var allBlueArray: Array = []
	var allYellowArray: Array = []
	var allPinkArray: Array = []
	var allGreenArray: Array = []
	for length in columns:
		for width in rows:
			if get_cell_tile_data(0, Vector2i(xCount, yCount)):
				var makeSpriteMatch: AnimatedSprite2D = $"../AnimatingControl".get_child(availableTileSpaces.find(Vector2i(xCount, yCount)))
				var sourceID: int = get_cell_source_id(0, Vector2i(xCount, yCount))
				makeSpriteMatch.modulate = modulatedColorArray[sourceID]
				match sourceID:
					0:
						allRedArray.append(Vector2i(xCount, yCount))
					1:
						allGreenArray.append(Vector2i(xCount, yCount))
					2:
						allBlueArray.append(Vector2i(xCount, yCount))
					3:
						allPinkArray.append(Vector2i(xCount, yCount))
					4:
						allYellowArray.append(Vector2i(xCount, yCount))
			xCount += 1
			if xCount > 6:
				xCount = 1
				yCount+=1
	tileMatchingDict["Red"] = allRedArray
	tileMatchingDict["Blue"] = allBlueArray
	tileMatchingDict["Pink"] = allPinkArray
	tileMatchingDict["Yellow"] = allYellowArray
	tileMatchingDict["Green"] = allGreenArray
	

# Called to make the tiles fall after match
func tilemap_move_cells():
	var firstColumn: Array = []
	var secondColumn: Array = []
	var thirdColumn: Array = []
	var fourthColumn: Array = []
	var fifthColumn: Array = []
	var sixthColumn: Array = []
	for i in availableTileSpaces:
		# First gather all the valid
		# tiles available by column
		if get_cell_tile_data(0, i):
			if sound:
				$"../TileMoveSound".play()
			match i.x:
				1:
					firstColumn.append(i)
				2:
					secondColumn.append(i)
				3:
					thirdColumn.append(i)
				4:
					fourthColumn.append(i)
				5:
					fifthColumn.append(i)
				6:
					sixthColumn.append(i)
	if firstColumn.size()>0:
		# Reverse the arrays now, we want 
		# to start the move from the bottom.
		firstColumn.reverse()
		for i in firstColumn:
			# Add one to column_array_pos[i].y to see if the tile is availbale to move to.
			if !get_cell_tile_data(0, Vector2i(i.x, i.y + 1)) and availableTileSpaces.has(Vector2i(i.x, i.y + 1)):
				# if the tilemap has no data and the array has the data.
				set_cell(0, Vector2i(i.x, i.y + 1), get_cell_source_id(0, i), Vector2i(0, 0))
				set_cell(0, Vector2i(i.x, i.y), -1)
	if secondColumn.size()>0:
		secondColumn.reverse()
		for i in secondColumn:
			if !get_cell_tile_data(0, Vector2i(i.x, i.y + 1)) and availableTileSpaces.has(Vector2i(i.x, i.y + 1)):
				set_cell(0, Vector2i(i.x, i.y + 1), get_cell_source_id(0, i), Vector2i(0, 0))
				set_cell(0, Vector2i(i.x, i.y), -1)
	if thirdColumn.size()>0:
		thirdColumn.reverse()
		for i in thirdColumn:
			if !get_cell_tile_data(0, Vector2i(i.x, i.y + 1)) and availableTileSpaces.has(Vector2i(i.x, i.y + 1)):
				set_cell(0, Vector2i(i.x, i.y + 1), get_cell_source_id(0, i), Vector2i(0, 0))
				set_cell(0, Vector2i(i.x, i.y), -1)
	if fourthColumn.size()>0:
		fourthColumn.reverse()
		for i in fourthColumn:
			if !get_cell_tile_data(0, Vector2i(i.x, i.y + 1)) and availableTileSpaces.has(Vector2i(i.x, i.y + 1)):
				set_cell(0, Vector2i(i.x, i.y + 1), get_cell_source_id(0, i), Vector2i(0, 0))
				set_cell(0, Vector2i(i.x, i.y), -1)
	if fifthColumn.size()>0:
		fifthColumn.reverse()
		for i in fifthColumn:
			if !get_cell_tile_data(0, Vector2i(i.x, i.y + 1)) and availableTileSpaces.has(Vector2i(i.x, i.y + 1)):
				set_cell(0, Vector2i(i.x, i.y + 1), get_cell_source_id(0, i), Vector2i(0, 0))
				set_cell(0, Vector2i(i.x, i.y), -1)
	if sixthColumn.size()>0:
		sixthColumn.reverse()
		for i in sixthColumn:
			if !get_cell_tile_data(0, Vector2i(i.x, i.y + 1)) and availableTileSpaces.has(Vector2i(i.x, i.y + 1)):
				set_cell(0, Vector2i(i.x, i.y + 1), get_cell_source_id(0, i), Vector2i(0, 0))
				set_cell(0, Vector2i(i.x, i.y), -1)
	request_new_tiles()
	# It would be easy to use some of the techniques used 
	# in this tutorial here to tween some move animations, 
	# so feel free to have fun.
	

# Let switch happen, then check for 
# all possible matches with 
# tilemap_check_all_data()
# If not a match, swap back.
func drop_swap_pieces():
	for i in $"../AnimatingControl".get_children():
		i.hide()
		i.play("Happy")
	if canSwap:
		checkMove = true
		set_cell(0, swapStart, swapTileTo, Vector2i(0,0))
		set_cell(0, swapEnd, swapTileFrom, Vector2i(0,0))
		tilemap_check_all_data()
		await get_tree().create_timer(0.2).timeout
		if !tilemap_animate_cells():
			if sound:
				$"../WrongMoveSound".play()
			set_cell(0, swapStart, swapTileFrom, Vector2i(0,0))
			set_cell(0, swapEnd, swapTileTo, Vector2i(0,0))
			checkMove = false
	# After we drop the pieces, reset canSwap.
	canSwap = false
	

func load_save_file(loadingFileLocation: String):
	if DirAccess.dir_exists_absolute(loadingFileLocation):
		if FileAccess.file_exists(loadingFileLocation+saveFile):
			var loadFile = FileAccess.open(saveLocation+saveFile, FileAccess.READ)
			saveDict = str_to_var(loadFile.get_as_text())
			loadFile.close()
			bestScore = saveDict["BestScore"]
			music = saveDict["MusicOn"]
			$"../LoadingNode/PauseControl/Music".set_pressed_no_signal(saveDict["MusicOn"])
			sound = saveDict["SoundOn"]
			$"../LoadingNode/PauseControl/Sound".set_pressed_no_signal(saveDict["SoundOn"])
			$"../LoadingNode/LoadingControl/BestScoreLabel/Amount".text = str(saveDict["BestScore"])
			if !music:
				$"../GameMusic".stream_paused = true
			else:
				$"../GameMusic".stream_paused = false
	else:
		DirAccess.make_dir_absolute(loadingFileLocation)
	save_game_file()
	$"../LoadingNode/LoadingControl/BestScoreLabel/Amount".text = str(bestScore)
	

func save_game_file():
	saveDict = {"BestScore": bestScore, "MusicOn": music, "SoundOn": sound}
	var savingFile = FileAccess.open(saveLocation+saveFile, FileAccess.WRITE)
	savingFile.store_string(var_to_str(saveDict))
	savingFile.close()
	

func _on_quit_button_pressed():
	get_tree().quit(0)
	

func _on_resume_button_pressed():
	get_tree().paused = false
	$"../LoadingNode/PauseControl".hide()
	if music:
		$"../GameMusic".stream_paused = false
	else:
		$"../GameMusic".stream_paused = true
	

func _on_music_toggled(toggled_on):
	music = toggled_on
	

func _on_sound_toggled(toggled_on):
	sound = toggled_on
	

func _on_puzzle_game_tree_exiting():
	save_game_file()
	
