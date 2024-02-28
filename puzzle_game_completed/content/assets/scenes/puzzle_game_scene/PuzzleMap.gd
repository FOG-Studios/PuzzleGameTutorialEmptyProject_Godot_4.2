extends TileMap

# Puzzle Game Using Tilemap

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
var level: int = 1
var changeLevels: bool = false
var levelUpScore: int = 500

var helpAmount: int = 3

#
# Make sure you set the ui_pause in project settings
# under input map tab, and in the add new action text box.
# If you're not sure how, consider looking at a previous
# tutorial I made on the game setup.
#
 
func _ready():
	randomize()
	$"../LevelControl/BorderControl/AiHelpButton/Amount".text = str(helpAmount)
	# Run the game once in the editor before 
	# you export to generate the levels txt 
	# with one of the following functions. 
	# Afterwards, block it back out.
	
	#build_levels_for_text(99)
	#copy_level_for_text(1)
	
	# If you don't block out or delete the functions
	# from ready, they will generate new tiles 
	# everytime the game is loaded, which could 
	# result in errors and cause the game to crash.
	
	colorArray = [
		Color(0.62, 0.208, 0.208, 0.8), Color(0.255, 0.694, 0.255, 0.8), 
		Color(0.353, 0.31, 0.714, 0.8), Color(0.945, 1, 0.592, 0.8), 
		Color(0.796, 0.467, 1, 0.8)
		]
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
	changeLevels = false
	

func _unhandled_input(event):
	if Input.is_action_pressed("ui_pause"):
		get_tree().paused = true
		$"../LoadingNode/PauseControl".show()
	if checkMove or changeLevels:
		return
	if event is InputEventScreenTouch and event.pressed:
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
			# Add the new check here
			if availableTileSpaces.has(i) and !get_used_cells(1).has(i):
				# First, just hiding the sprite here for
				# the quick changes from input
				$"../AnimatingControl".get_child(availableTileSpaces.find(i)).hide()
				# This is where we highlight the selected sprites.
				if makeSwapLocal == i:
					if !makeSwapLocal == swapEnd and sound:
						# swapEnd check here makes the sound
						# play just once.
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
							swapTileTo = 0
						1:
							swapTileTo = 1
						2:
							swapTileTo = 2
						3:
							swapTileTo = 3
						4:
							swapTileTo = 4
					# Be sure to jump out of function here,
					# we found a valid tile. If no valid tile
					# is found we just keep canSwap false.
					canSwap = true
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
	if sound and !$"../ScoreSound".is_playing():
		$"../ScoreSound".play()
	if score > bestScore:
		bestScore = score
		$"../LoadingNode/LoadingControl/BestScoreLabel/Amount".text = str(bestScore)#
		$"../LevelControl/BorderControl/TopBorder/ScoreLabel/Amount".add_theme_color_override("font_color", Color.GREEN)
	$"../LevelControl/BorderControl/TopBorder/ScoreLabel/Amount".text = str(score)
	if score>=levelUpScore + (level*levelUpScore):
		changeLevels = true
		change_levels()
	

func request_new_tiles():
	# New slot color array is used to store the 
	# old colors. If any change happens, we 
	# want to the changes to happen together and
	# after our animation is complete. Otherwise, 
	# we just set the color the same with no harm.
	var newSlotColorArray: Array = [newSlot_1Color, newSlot_2Color, newSlot_3Color, newSlot_4Color, newSlot_5Color, newSlot_6Color]
	var firstRowArray: Array = [Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2), Vector2i(5, 2), Vector2i(6, 2)]
	var addNewTileArray: Array = []
	for i in firstRowArray:
		if get_cell_tile_data(1, i) and !get_cell_tile_data(0, i):
			var slotCount: int = 1
			var tilesMoving: int = 0
			var tilesOpen: int = 0
			for emptySlots in 7:
				if !get_cell_tile_data(0, i+Vector2i(0, slotCount)) and !get_cell_tile_data(1, i+Vector2i(0, slotCount)):
					tilesOpen += 1
				elif get_cell_tile_data(0, i+Vector2i(0, slotCount)) and get_cell_tile_data(1, i+Vector2i(0, slotCount)):
					tilesMoving+=1
				slotCount += 1
			if tilesMoving<tilesOpen:
				addNewTileArray.append(i)
		elif !get_cell_tile_data(0, i) and !get_cell_tile_data(1, i):
			addNewTileArray.append(i)
	for newTile in addNewTileArray:
		match firstRowArray.find(newTile):
			0:
				var slotAnimTween: Tween = create_tween()
				slotAnimTween.tween_property(slot_1, "custom_minimum_size", Vector2(64, 64), 0.1)
				newSlot_1Color = randi_range(0, 4)
			1:
				var slotAnimTween: Tween = create_tween()
				slotAnimTween.tween_property(slot_2, "custom_minimum_size", Vector2(64, 64), 0.1)
				newSlot_2Color = randi_range(0, 4)
			2:
				var slotAnimTween: Tween = create_tween()
				slotAnimTween.tween_property(slot_3, "custom_minimum_size", Vector2(64, 64), 0.1)
				newSlot_3Color = randi_range(0, 4)
			3:
				var slotAnimTween: Tween = create_tween()
				slotAnimTween.tween_property(slot_4, "custom_minimum_size", Vector2(64, 64), 0.1)
				newSlot_4Color = randi_range(0, 4)
			4:
				var slotAnimTween: Tween = create_tween()
				slotAnimTween.tween_property(slot_5, "custom_minimum_size", Vector2(64, 64), 0.1)
				newSlot_5Color = randi_range(0, 4)
			5:
				var slotAnimTween: Tween = create_tween()
				slotAnimTween.tween_property(slot_6, "custom_minimum_size", Vector2(64, 64), 0.1)
				newSlot_6Color = randi_range(0, 4)
	var tweenTimer: Tween = create_tween()
	tweenTimer.tween_interval(0.1)
	await tweenTimer.finished
	for addNewTile in addNewTileArray:
		set_cell(0, addNewTile, newSlotColorArray[firstRowArray.find(addNewTile)], Vector2i(0, 0))
		if get_cell_tile_data(1, addNewTile):
			var animNode: AnimatedSprite2D = $"../AnimatingControl".get_child(availableTileSpaces.find(addNewTile))
			animNode.modulate = modulatedColorArray[newSlotColorArray[firstRowArray.find(addNewTile)]]
			animNode.play("Drop")
			animNode.show()
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
	await get_tree().create_timer(0.1).timeout
	for i in $"../AnimatingControl".get_children():
		i.hide()
		i.play("Happy")
	tilemap_move_cells()
	# Check to make sure all tiles moved
	# in place.
	

# Called to remove the matching tiles
# and start fall animation. The return
# value is linked to the tile drop.
# If it returns false, means that the 
# drops did not produce any valid matches.
func tilemap_animate_cells()->bool:
	checkMove = true
	var newDict: Dictionary = tilemap_check_all_data()
	var matchingPieceTotal: int = 0
	# The dictionary stays consistant once you make it.
	# So as long as we call the check all tile data, we'll
	# get a continous update of available tiles.
	for key in newDict:
		var matchingTilesArray: Array = []
		for tile in newDict[key]:
			# Notice the check on the values. We don't
			# have to worry about a valid tile check here either
			# because we're using the updated information from 
			# the tilemap.
			if newDict[key].has(tile+Vector2i.LEFT) and newDict[key].has(tile + Vector2i.RIGHT):
				# Check that it's not already in there, you can add 
				# the same value twice to an array.
				if !matchingTilesArray.has(tile+Vector2i.LEFT):
					matchingTilesArray.append(tile+Vector2i.LEFT)
				if !matchingTilesArray.has(tile+Vector2i.RIGHT):
					matchingTilesArray.append(tile+Vector2i.RIGHT)
				if !matchingTilesArray.has(tile):
					matchingTilesArray.append(tile)
			if newDict[key].has(tile+Vector2i.UP) and newDict[key].has(tile + Vector2i.DOWN):
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
	if matchingPieceTotal > 0 or get_used_cells(0).size() < (48 - get_used_cells(1).size()):
		# The timer is only used for drop simulation
		var timerTween: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
		timerTween.tween_interval(0.75)
		timerTween.tween_callback(tilemap_move_cells)
	elif matchingPieceTotal == 0 and !ai_check_gameover():#
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
func tilemap_check_all_data()-> Dictionary:
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
	return tileMatchingDict
	

# Called to make the tiles fall after match
func tilemap_move_cells():
	# Drop the tile in the planned empty space first.
	var movesLeft: bool = false
	var allSpaces: Array = availableTileSpaces.duplicate()
	allSpaces.reverse()
	# Now get all the non-empty tiles.
	for tile in allSpaces:
		if get_cell_tile_data(0, tile) and availableTileSpaces.has(Vector2i(tile.x, tile.y+1)):
			if !get_cell_tile_data(0, Vector2i(tile.x, tile.y+1)) and !get_cell_tile_data(1, Vector2i(tile.x, tile.y+1)):
				set_cell(0, Vector2i(tile.x, tile.y+1), get_cell_source_id(0, tile), Vector2i(0,0))
				set_cell(0, tile, -1)
			elif get_cell_tile_data(1, Vector2i(tile.x, tile.y+1)):
				var ySteps: int = 1 # Counts down
				var tilesMoving: int = 0
				var tilesEmpty: int = 0
				for squares in 7:
					if !availableTileSpaces.has(Vector2i(tile.x, tile.y+ySteps)):
						break
					if get_cell_tile_data(0, Vector2i(tile.x, tile.y+ySteps)) and get_cell_tile_data(1, Vector2i(tile.x, tile.y+ySteps)):
						# Glass with tile means nothing under it dropped
						tilesMoving += 1
					elif !get_cell_tile_data(0, Vector2i(tile.x, tile.y+ySteps)) and !get_cell_tile_data(1, Vector2i(tile.x, tile.y+ySteps)):
						# Empty space
						tilesEmpty += 1
					ySteps+=1
				if tilesEmpty > tilesMoving:
					set_cell(0, Vector2i(tile.x, tile.y+1), get_cell_source_id(0, tile), Vector2i(0,0))
					set_cell(0, tile, -1)
	if sound:
		$"../TileMoveSound".play()
	for i in availableTileSpaces:
		if get_cell_tile_data(0, i) and get_cell_tile_data(1, i):
			var animNode: AnimatedSprite2D = $"../AnimatingControl".get_child(availableTileSpaces.find(i))
			animNode.modulate = modulatedColorArray[get_cell_source_id(0, i)]
			animNode.play("Drop")
			animNode.show()
			movesLeft = true
	var internalTimer: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	internalTimer.tween_interval(0.3)
	await internalTimer.finished
	
	# Check for empties again
	if get_used_cells(0).size() < (48-get_used_cells(1).size()):
		request_new_tiles()
		return
	elif movesLeft:
		for i in $"../AnimatingControl".get_children():
			i.hide()
		await get_tree().create_timer(0.2).timeout
		call_deferred("tilemap_move_cells")
	else:
		for i in $"../AnimatingControl".get_children():
			i.hide()
		tilemap_animate_cells()
		
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
	if canSwap:
		set_cell(0, swapStart, swapTileTo, Vector2i(0,0))
		set_cell(0, swapEnd, swapTileFrom, Vector2i(0,0))
		if !tilemap_animate_cells():
			if sound:
				$"../WrongMoveSound".play()
			set_cell(0, swapStart, swapTileFrom, Vector2i(0,0))
			set_cell(0, swapEnd, swapTileTo, Vector2i(0,0))
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
			sound = saveDict["SoundOn"]
			level = saveDict["Level"]
	else:
		DirAccess.make_dir_absolute(loadingFileLocation)
	$"../GameMusic".stream_paused = !music
	$"../LoadingNode/PauseControl/Music".set_pressed_no_signal(music)
	$"../LoadingNode/PauseControl/Sound".set_pressed_no_signal(sound)
	save_game_file()
	if FileAccess.file_exists("res://save_folder/level_dictionary/Level_Saves.txt"):
		await load_level_from_text(level)#
		$"../LevelControl/BorderControl/TopBorder/LevelLabel/Amount".text = str(level)
		$"../LevelControl/BorderControl/TopBorder/NextLevelPoints".text = str(levelUpScore + (level*levelUpScore))
		$"../LoadingNode/LoadingControl/ReadyButton".show()
		$"../LoadingNode/LoadingControl/BestScoreLabel/Amount".text = str(saveDict["BestScore"])
		$"../LoadingNode/LoadingControl/BestScoreLabel/Amount".text = str(bestScore)
	else:
		build_levels_for_text(99)
	

func save_game_file():
	saveDict = {"BestScore": bestScore, "MusicOn": music, "SoundOn": sound, "Level": level}
	var savingFile = FileAccess.open(saveLocation+saveFile, FileAccess.WRITE)
	savingFile.store_string(var_to_str(saveDict))
	savingFile.close()
	

func _on_quit_button_pressed():
	get_tree().quit(0)
	

func _on_resume_button_pressed():
	get_tree().paused = false
	$"../LoadingNode/PauseControl".hide()
	$"../GameMusic".stream_paused = !music
	

func _on_music_toggled(toggled_on):
	music = toggled_on
	

func _on_sound_toggled(toggled_on):
	sound = toggled_on
	

func _on_puzzle_game_tree_exiting():
	save_game_file()
	

func change_levels():
	if !checkMove:
		# I added a check here for the 
		# maximum level amount. If we don't 
		# have levels here, it will crash 
		# the game.
		# Alternatively, you could call 
		# build_levels_for_text(updatedValue)
		# here with the updated level value, 
		# then be sure to load it from the 
		# load_level_from_text(updatedLevelNum).
		# It is also possbile with that way to 
		# build the levels dynamically. i.e...
		# Once you beat level 1, call 
		# build_levels_for_text(updatedLevelNum)
		# You could delay with a timer, or simply
		# choose in the build_levels_for_text 
		# function, have it load the level 
		# after completion.
		helpAmount = 3
		if level != 99:
			level += 1
		else:
			level = 1
			score = 0
		$"../LoadingNode/LoadingControl/LoadingLabel".show()
		$"../LoadingNode/LoadingControl".show()
		$"../LoadingNode/LoadingControl/NewLevelLabel".show()
		$"../LoadingNode/LoadingControl/ReadyButton".hide()
		await load_level_from_text(level)
		$"../LevelControl/BorderControl/TopBorder/LevelLabel/Amount".text = str(level)
		$"../LevelControl/BorderControl/TopBorder/NextLevelPoints".text = str(levelUpScore + (level*levelUpScore))
		$"../LoadingNode/LoadingControl/ReadyButton".show()
		$"../LoadingNode/LoadingControl/BestScoreLabel/Amount".text = str(saveDict["BestScore"])
		$"../LoadingNode/LoadingControl/BestScoreLabel/Amount".text = str(bestScore)
	else:
		$"../NewLevelCheckTimer".start()
	

func build_levels_for_text(levelsToMake: int):
	var buildLevelsDict: Dictionary = {}
	var stageCount: int = 1
	var emptyCount: int = 0
	var levelCount: int = 1
	for levels in levelsToMake:
		var emptyTileArray: Array = []
		for i in emptyCount:
			emptyTileArray.append(availableTileSpaces.pick_random())
		buildLevelsDict[str(levelCount)] = emptyTileArray
		stageCount += 1
		if stageCount == 11:
			stageCount = 1
			emptyCount += 1
			if levels > 89:
				emptyCount = 10
		levelCount += 1
	var savingFile = FileAccess.open("res://save_folder/level_dictionary/Level_Saves.txt", FileAccess.WRITE)
	savingFile.store_string(var_to_str(buildLevelsDict))
	savingFile.close()
	

func load_level_from_text(levelNum: int)-> bool:
	var storedLevels: Dictionary = {}
	var loadFile = FileAccess.open("res://save_folder/level_dictionary/Level_Saves.txt", FileAccess.READ)
	storedLevels = str_to_var(loadFile.get_as_text())
	loadFile.close()
	clear()
	for glass in storedLevels[str(levelNum)]:
		set_cell(1, glass, 5, Vector2i(0,0))
	for i in availableTileSpaces:
		if !get_used_cells(1).has(i):
			set_cell(0, i, randi_range(0, 4), Vector2i(0, 0))
	await get_tree().create_timer(1.0).timeout
	return true
	

func copy_level_for_text(chosenLevelNum: int):
	var newDict: Dictionary = {}
	var glassArray: Array = []
	if FileAccess.file_exists("res://save_folder/level_dictionary/Level_Saves.txt"):
		var loadedDict = FileAccess.open("res://save_folder/level_dictionary/Level_Saves.txt", FileAccess.READ)
		newDict = str_to_var(loadedDict.get_as_text())
		loadedDict.close()
	for i in get_used_cells(1):
		glassArray.append(i)
	newDict[str(chosenLevelNum)] = glassArray
	var savingFile = FileAccess.open("res://save_folder/level_dictionary/Level_Saves.txt", FileAccess.WRITE)
	savingFile.store_string(var_to_str(newDict))
	savingFile.close()
	

func ai_check_gameover()->bool:
	for tile in get_used_cells(0):
		var matchSourceID: int = get_cell_source_id(0, tile)
		var moveDirs: Array = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
		for dir in moveDirs:
			var matchingArray: Array = []
			var tileDirArray: Array
			var tempStart: Vector2i
			match dir:
				Vector2i.LEFT:
					tempStart = tile + Vector2i.LEFT
					if get_cell_tile_data(0, tempStart):
						tileDirArray = [Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]
				Vector2i.RIGHT:
					tempStart = tile + Vector2i.RIGHT
					if get_cell_tile_data(0, tempStart):
						tileDirArray = [Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
				Vector2i.UP:
					tempStart = tile + Vector2i.UP
					if get_cell_tile_data(0, tempStart):
						tileDirArray = [Vector2i.LEFT, Vector2i.UP, Vector2i.RIGHT]
				Vector2i.DOWN:
					tempStart = tile + Vector2i.DOWN
					if get_cell_tile_data(0, tempStart):
						tileDirArray = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]
			for checkDir in tileDirArray:
				var count: int = 1
				for i in 2:
					if get_cell_source_id(0, tempStart +(checkDir * count)) == matchSourceID:
						matchingArray.append(tempStart+ (checkDir * count))
					count += 1
			if matchingArray.size() > 0:
				if match_array(tempStart, matchingArray):
					return false
	
	for i in get_used_cells(0):
		set_cell(0, i, randi_range(0, 4), Vector2i(0,0))
	changeLevels = true
	$"../LoadingNode/GameOverControl".show()
	return changeLevels
	

func ai_help():
	if checkMove or grabbedPiece:
		return
	if helpAmount == 0:
		return
	helpAmount -= 1
	$"../LevelControl/BorderControl/AiHelpButton/Amount".text = str(helpAmount)
	for tile in get_used_cells(0):
		var matchSourceID: int = get_cell_source_id(0,tile)
		var moveDirs: Array = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
		for dir in moveDirs:
			var matchingArray: Array = []
			var tileDirArray: Array
			var tempStart: Vector2i
			match dir:
				Vector2i.LEFT:
					tempStart = tile + Vector2i.LEFT
					if get_cell_tile_data(0, tempStart):
						tileDirArray = [Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]
				Vector2i.RIGHT:
					tempStart = tile + Vector2i.RIGHT
					if get_cell_tile_data(0, tempStart):
						tileDirArray = [Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
				Vector2i.UP:
					tempStart = tile + Vector2i.UP
					if get_cell_tile_data(0, tempStart):
						tileDirArray = [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT]
				Vector2i.DOWN:
					tempStart = tile + Vector2i.DOWN
					if get_cell_tile_data(0, tempStart):
						tileDirArray = [Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	
			for checkDir in tileDirArray:
				var count: int = 1
				for i in 2:
					if get_cell_source_id(0, tempStart+(checkDir*count)) == matchSourceID:
						matchingArray.append(tempStart+(checkDir*count))
					count+= 1
			if matchingArray.size()>0:
				if match_array(tempStart, matchingArray):
					$"../AnimatingControl".get_child(availableTileSpaces.find(tile)).show()
	

func match_array(startCheckPos: Vector2i, checkArray: Array)-> bool:
	if checkArray.has(startCheckPos + (Vector2i.LEFT)) and checkArray.has(startCheckPos + (Vector2i.LEFT*2)):
		return true
	elif checkArray.has(startCheckPos + (Vector2i.RIGHT)) and checkArray.has(startCheckPos + (Vector2i.RIGHT*2)):
		return true
	elif checkArray.has(startCheckPos + (Vector2i.UP)) and checkArray.has(startCheckPos + (Vector2i.UP*2)):
		return true
	elif checkArray.has(startCheckPos + (Vector2i.DOWN)) and checkArray.has(startCheckPos + (Vector2i.DOWN*2)):
		return true
	elif checkArray.has(startCheckPos + Vector2i.LEFT) and checkArray.has(startCheckPos + Vector2i.RIGHT):
		return true
	elif checkArray.has(startCheckPos + Vector2i.UP) and checkArray.has(startCheckPos + Vector2i.DOWN):
		return true
	return false
	

func _on_game_over_retry_pressed():
	load_level_from_text(level)
	score = 0
	helpAmount = 3
	$"../LevelControl/BorderControl/AiHelpButton/Amount".text = str(helpAmount)
	$"../LevelControl/BorderControl/TopBorder/ScoreLabel/Amount".text = str(score)
	$"../LoadingNode/GameOverControl".hide()
	await get_tree().create_timer(1.0).timeout
	tilemap_animate_cells()
	changeLevels = false
	

func _on_ai_help_button_pressed():
	ai_help()
	
