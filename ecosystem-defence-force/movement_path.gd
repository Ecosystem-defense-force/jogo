extends PathFollow2D

const ENEMY_SPEED = 50 

func _process(delta):
	# O nó PathFollower avança a si mesmo
	progress += ENEMY_SPEED * delta
