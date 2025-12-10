extends Area2D

# Configurações de voo
var velocidade: float = 50
var alvo: Node2D = null
var dano: float = 0.0

func _physics_process(delta: float) -> void:
	# 1. Se o alvo morreu antes da bala chegar, a bala some
	if not is_instance_valid(alvo):
		queue_free()
		return

	# 2. Descobrir a direção
	var direcao = (alvo.global_position - global_position).normalized()
	
	# 3. Mover e Rotacionar
	global_position += direcao * velocidade * delta
	look_at(alvo.global_position)

	# 4. Checar se encostou (Distância menor que 10 pixels)
	if global_position.distance_to(alvo.global_position) < 10.0:
		acertar_alvo()

func acertar_alvo() -> void:
	# Chama a função de dano do inimigo (igual você fazia na torre)
	if alvo.has_method("tomou_dano"):
		alvo.tomou_dano(dano)
	
	# Efeito visual opcional: Instanciar uma explosão aqui antes de deletar
	
	queue_free() # Destroi a bala

# Esta função é chamada pela Torre quando a bala nasce
func iniciar(_posicao_inicial: Vector2, _alvo: Node2D, _dano: float) -> void:
	global_position = _posicao_inicial
	alvo = _alvo
	dano = _dano
