extends PathFollow2D

const ENEMY_SPEED = 30 
var damage: int = 10

func _process(delta):
	progress += ENEMY_SPEED * delta
	
	# DEBUG: Vamos ver se ele está chegando perto
	if progress_ratio > 0.9:
		print("Inimigo chegando... Ratio: ", progress_ratio)

	if progress_ratio >= 1.0:
		print("Inimigo atingiu 100% do caminho!") # <--- Se isso não aparecer, ele não está entrando aqui
		reach_base()

func reach_base():
	print("Chamando GameManager...")
	# Verifica se o GameManager existe antes de chamar
	if GameManager:
		GameManager.base_hp -= damage
		print("Dano aplicado. Vida nova deve ser menor.")
	else:
		print("ERRO: GameManager não encontrado!")
		
	queue_free()
