# Mary Grady
# mtg48

# this .include has to be up here so we can use the constants in the variables below.
.include "game_constants.asm"

# ------------------------------------------------------------------------------------------------
.data

# Player coordinates, in tiles. These initializers are the starting position.
player_x: .word 6
player_y: .word 5

# Direction player is facing.
player_dir: .word DIR_S

# How many hits the player can take until a game over.
player_health: .word 3

# How many keys the player has.
player_keys: .word 0

# 0 = player can move a tile, nonzero = they can't
player_move_timer: .word 0

# 0 = normal, nonzero = player is invincible and flashing.
player_iframes: .word 0

# 0 = no sword out, nonzero = sword is out
player_sword_timer: .word 0

# 0 = can place bomb, nonzero = can't place bomb
player_bomb_timer: .word 0

# boolean: did the player pick up the treasure?
player_got_treasure: .word 0

# Camera coordinates, in tiles. This is the top-left tile being displayed onscreen.
# This is derived from the player coordinates, so these initial values don't mean anything.
camera_x: .word 0
camera_y: .word 0

# Object arrays. These are parallel arrays.
object_type:  .byte OBJ_EMPTY:NUM_OBJECTS
object_x:     .byte 0:NUM_OBJECTS
object_y:     .byte 0:NUM_OBJECTS
object_timer: .byte 0:NUM_OBJECTS # general-purpose timer

# A 2D array of tile types. Filled in by load_map.
playfield: .byte 0:MAP_TILE_NUM

# A pair of arrays, indexed by direction, to turn a direction into x/y deltas.
# e.g. direction_delta_x[DIR_E] is 1, because moving east increments X by 1.
#                         N  E  S  W
direction_delta_x: .byte  0  1  0 -1
direction_delta_y: .byte -1  0  1  0

.text

# ------------------------------------------------------------------------------------------------

# these .includes are here to make these big arrays come *after* the interesting
# variables in memory. it makes things easier to debug.
.include "display_2211_0822.asm"
.include "textures.asm"
.include "map.asm"
.include "obj.asm"

# ------------------------------------------------------------------------------------------------

.globl main
main:
	# load the map into the 'playfield' array
	jal load_map

	# wait for the game to start
	jal wait_for_start

	# main game loop
	_loop:
		jal check_input
		jal update_all
		jal draw_all
		jal display_update_and_clear
		jal wait_for_next_frame
	jal check_game_over
	beq v0, 0, _loop

	# when the game is over, show a message
	jal show_game_over_message
syscall_exit

# ------------------------------------------------------------------------------------------------

wait_for_start:
enter
	_loop:
		jal draw_all
		jal display_update_and_clear
		jal wait_for_next_frame
	jal input_get_keys_pressed
	beq v0, 0, _loop
leave

# ------------------------------------------------------------------------------------------------

# returns a boolean (1/0) of whether the game is over. 1 means it is.
check_game_over:
enter
	li v0, 0
	# TODO: the rest of the function.
leave

# ------------------------------------------------------------------------------------------------

show_game_over_message:
enter
	# TODO
leave

# ------------------------------------------------------------------------------------------------

# Get input from the user and move the player object accordingly.
check_input:
enter s0

	jal input_get_keys_held
	move s0,v0

	#if(s0 & KEY_U) try_move_player(DIR_N)
	and t0, s0, KEY_U
	beq t0, 0, _endif_u
			li a0, DIR_N
			jal try_move_player
			j _endif
	_endif_u:

	#if(s0 & KEY_R) try_move_player(DIR_E)
	and t0, s0, KEY_R
	beq t0, 0, _endif_r
			li a0, DIR_E
			jal try_move_player
			j _endif
	_endif_r:


	#if(s0 & KEY_D) try_move_player(DIR_S)
	and t0, s0, KEY_D
	beq t0, 0, _endif_d
			li a0, DIR_S
			jal try_move_player
			j _endif
	_endif_d:

	#if(s0 & KEY_L) try_move_player(DIR_W)
	and t0, s0, KEY_L
	beq t0, 0, _endif_l
			li a0, DIR_W
			jal try_move_player
			j _endif
	_endif_l:

	_endif:



leave s0

try_move_player:
enter #s0, s1


	lw t0, player_dir
	move t0, a0
	#beq t0, a0, _theyEQL
	#move t0, a0
	#lw v0, player_move_timer
	#lw v1, PLAYER_MOVE_DELAY
	#move v0, v1


	#lw t0, player_move_timer
	#beq t0, 0, _notTrue #if(player_move_timer != 0----> go to _notTrue)
	#lw v0, player_move_timer
	#lw v1, PLAYER_MOVE_DELAY
	#move v0, v1


	mul t0, t0, 4

	lw v0, player_x
	lb t1, direction_delta_x(t0)
	add v0, v0, t1 # player_x = player_x + direction_delta_x[a0]

	lw v1, player_y
	lb t2, direction_delta_y(t0)# player_y = player_y + direction_delta_x[a0]
	add v1,v1, t2

	#blt s0, 0, _else
	#bge s0, MAP_TILE_W, _else
	#blt s1, 0, _else
	#bge s1, MAP_TILE_H, _else


	#move v0, s0 # player_x = s0
	#sw v0, player_x
	#move v1, s1# player_y = s1
	#sw v1, player_y


	#_else:

	#_notTrue:

	#_theyEQL:


leave #s0, s1

# ------------------------------------------------------------------------------------------------

# calculate the position in front of the player based on their coordinates and direction.
# returns v0 = x, v1 = y.
# the returned position can be *outside the map,* so be careful!
position_in_front_of_player:
enter
	lw  t1, player_dir

	lw  v0, player_x
	lb  t0, direction_delta_x(t1)
	add v0, v0, t0

	lw  v1, player_y
	lb  t0, direction_delta_y(t1)
	add v1, v1, t0
leave

# ------------------------------------------------------------------------------------------------

# update all the parts of the game and do collision between objects.
update_all:
enter
	jal update_camera
	jal update_timers
	jal obj_update_all
	jal collide_sword
leave

# ------------------------------------------------------------------------------------------------

# positions camera based on player position, but doesn't
# let it move off the edges of the playfield.
update_camera:
enter
	#lw t0, player_x
	#add v0, t0, CAMERA_OFFSET_X
	#maxi v0, v0, 0
	#mini v0, v0, CAMERA_OFFSET_X
	#sw v0, camera_x

	#lw t0, player_y
	#add v0, t0, CAMERA_OFFSET_Y
	#maxi v0, v0, 0
	#mini v0, v0, CAMERA_OFFSET_Y
	#sw v0, camera_y

leave

# ------------------------------------------------------------------------------------------------

update_timers:
enter
	lw t0, player_move_timer
	sub t0, t0, 1
	maxi t0, t0, 0
	sw t0, player_move_timer
leave

# ------------------------------------------------------------------------------------------------

collide_sword:
enter
	# TODO
leave

# ------------------------------------------------------------------------------------------------

# a0 = object index
# you don't call this, obj_update_all does!
obj_update_bomb:
enter
	# TODO
leave

# ------------------------------------------------------------------------------------------------

# a0 = object index
# you don't call this, obj_update_all does!
obj_update_explosion:
enter
	# TODO
leave

# ------------------------------------------------------------------------------------------------

# a0 = object index
# you don't call this, obj_update_all does!
obj_update_key:
enter s0
	move s0, a0

	#if the player is touching this key

leave s0

# ------------------------------------------------------------------------------------------------

# a0 = object index
# you don't call this, obj_update_all does!
obj_update_blob:
enter
	# TODO
leave

# ------------------------------------------------------------------------------------------------

# a0 = object index
# you don't call this, obj_update_all does!
obj_update_treasure:
enter
	# TODO
leave

# ------------------------------------------------------------------------------------------------

draw_all:
enter
	jal draw_playfield
	jal obj_draw_all
	jal draw_player
	jal draw_sword
	jal draw_hud
leave

# ------------------------------------------------------------------------------------------------

draw_playfield:
enter s0, s1

li s0, 0 #row=0


_TrueRow:

li s1, 0 #col=0

	_TrueCol:


	lw a0, camera_x
	lw a1, camera_y

	move a0, s1
	move a1, s0

	jal get_tile

	mul v0, v0, 4
	lw a2, tile_textures(v0)

		beq a2, 0, _notTrueIf

		mul a0, s1, 5
		add a0, a0, PLAYFIELD_TL_X

		mul a1, s0, 5
		add a1, a1, PLAYFIELD_TL_Y

		jal display_blit_5x5

		j _endIf

		_notTrueIf:

		_endIf:

	add s1, s1, 1 #col++
	blt s1, SCREEN_TILE_W, _TrueCol

add s0, s0, 1 #row++
blt s0, SCREEN_TILE_H, _TrueRow


leave s0, s1

# ------------------------------------------------------------------------------------------------

draw_player:
enter
	lw a0, player_x
	lw a1, player_y

	#texture = player_textures[player_dir * 4]
	lw t0, player_dir
	mul t0, t0, 4
	lw a2, player_textures(t0)

	jal blit_5x5_tile_trans
leave

# ------------------------------------------------------------------------------------------------

draw_sword:
enter
	# TODO
leave

# ------------------------------------------------------------------------------------------------

draw_hud:
enter s0, s1
	# draw health
	lw s0, player_health
	li s1, 2
	_health_loop:
		move a0, s1
		li   a1, 1
		la   a2, tex_heart
		jal  display_blit_5x5_trans

		add s1, s1, 6
	dec s0
	bgt s0, 0, _health_loop

	li  a0, 20
	li  a1, 1
	li  a2, 'Z'
	jal display_draw_char

	li  a0, 26
	li  a1, 1
	la  a2, tex_sword_N
	jal display_blit_5x5_trans

	li  a0, 32
	li  a1, 1
	li  a2, 'X'
	jal display_draw_char

	li  a0, 38
	li  a1, 1
	la  a2, tex_bomb
	jal display_blit_5x5_trans

	li  a0, 44
	li  a1, 1
	li  a2, 'C'
	jal display_draw_char

	li  a0, 50
	li  a1, 1
	la  a2, tex_key
	jal display_blit_5x5_trans

	li   a0, 56
	li   a1, 1
	lw   a2, player_keys
	mini a2, a2, 9 # limit it to at most 9
	jal  display_draw_int
leave s0, s1

# ------------------------------------------------------------------------------------------------

# a0 = object index
# you don't call this, obj_draw_all does!
obj_draw_bomb:
enter
	# TODO
leave

# ------------------------------------------------------------------------------------------------

# a0 = object index
# you don't call this, obj_draw_all does!
obj_draw_explosion:
enter
	# TODO
leave

# ------------------------------------------------------------------------------------------------

# a0 = object index
# you don't call this, obj_draw_all does!
obj_draw_key:
enter
	#TODO
leave

# ------------------------------------------------------------------------------------------------

# a0 = object index
# you don't call this, obj_draw_all does!
obj_draw_blob:
enter
	# TODO
leave

# ------------------------------------------------------------------------------------------------

# a0 = object index
# you don't call this, obj_draw_all does!
obj_draw_treasure:
enter
	# TODO
leave
