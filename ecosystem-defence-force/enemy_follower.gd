extends PathFollow2D

const ENEMY_SPEED = 50 

func _process(delta):
	# apenas avança o nó PathFollow2D no caminho
	progress += ENEMY_SPEED * delta
