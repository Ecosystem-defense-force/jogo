extends Resource
class_name SpawnInimigo

@export var duracao: float = 5.0 # Tempo total para spawnar essa quantidade
@export var quantidade: int = 3  # Quantos inimigos vão aparecer
# Aqui usaremos um ID simples (0 = Lenhador, 1 = Mandrake)
@export var tipos_inimigos: Array[int] = [0] 

func pegar_inimigo_aleatorio() -> int:
	if tipos_inimigos.is_empty():
		return 0
	return tipos_inimigos.pick_random()
