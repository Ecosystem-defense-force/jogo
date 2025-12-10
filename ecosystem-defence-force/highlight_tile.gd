class_name HighlightTile
extends Node2D

func _process(delta: float) -> void: 
	follow_mouse_position()

#pega a posição do mouse e cria uma celula de 16x16
func follow_mouse_position() -> void: 
	var mouse_position : Vector2i = get_global_mouse_position() / 16
	
	position = mouse_position * 16

	
	
	
