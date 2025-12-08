extends Node2D

# velocidade do inimigo 
const ENEMY_SPEED = 50 

func _process(delta):
	# acessa o nó que está seguindo o Path2D
	var path_follow = get_parent() 
	
	# incrementa o progresso do caminho
	# isso move o PathFollow2D ao longo da linha desenhada
	path_follow.progress += ENEMY_SPEED * delta
	
	# atualiza a posição inimigo para a posição do path follow
	global_position = path_follow.global_position
