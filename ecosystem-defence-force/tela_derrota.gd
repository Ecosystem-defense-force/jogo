extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func _on_menu_pressed() -> void:
	# Reseta os dados ANTES de mudar a cena
	GameManager.reset_game() 
	
	# Troca para o menu
	get_tree().change_scene_to_file("res://MenuPrincipal.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit() # Replace with function body.
