extends Node

var current_checkpoint : Checkpoint

var player_alive : bool
var playerBody :CharacterBody2D
var playerDamageZone : Area2D
var playerDamageAmount : int
var is_dashing : bool

var batDamageZone : Area2D
var batDamageAmount : int


func hit_stop_short():
	Engine.time_scale = 0
	await get_tree().create_timer(.04,true,false,true).timeout
	Engine.time_scale = 1

func respawn_player():
	if current_checkpoint != null:
		playerBody.position = current_checkpoint.global_position
	else:
		#placeholder. 
		playerBody.position = Vector2(290,176)
