
extends PathFollow2D
const ENEMY_SPEED = 30 

func _process(delta):
	progress += ENEMY_SPEED * delta
