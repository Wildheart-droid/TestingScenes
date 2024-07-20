extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	if scene_manager.player:
		add_child(scene_manager.player)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
