extends PathFollow2D
class_name InimigoBase

signal morreu(recompensa: int)
signal causou_dano_na_base(dano: int)

@export_category("Atributos")
@export var nome_inimigo: String = "Lenhador"
@export var velocidade: float = 100.0
@export var vida_maxima: float = 50.0
@export var dano_na_floresta: int = 25 # Quanto de vida tira da sua base
@export var recompensa_sementes: int = 5 # Dinheiro ganho ao derrotar

@export_category("Visual")
@export var sprite: AnimatedSprite2D
@export var barra_vida: ProgressBar
@export var floating_text_scene: PackedScene

@onready var game_manager = get_node("/root/GameManager")

var vida_atual: float

# --- NOVO: Função para a Torre saber quem está na frente ---
func obter_progresso_total() -> float:
	# Retorna a propriedade nativa do PathFollow2D (distância em pixels)
	return progress 
# -----------------------------------------------------------

func _ready() -> void:
	var indice_onda = game_manager.current_wave - 1
	if indice_onda < 0: indice_onda = 0
	
	# Balanceamento
	vida_maxima = vida_maxima * (1.0 + (indice_onda * 0.2))
	vida_atual = vida_maxima
	recompensa_sementes = recompensa_sementes + (indice_onda * 2) # Linha duplicada removida
	velocidade = velocidade * (1.0 + (indice_onda * 0.05))
	
	if sprite:
		sprite.play("andar")
	
	if barra_vida:
		barra_vida.max_value = vida_maxima
		barra_vida.value = vida_atual
		barra_vida.visible = false 

func _physics_process(delta: float) -> void:
	# Movimentação ao longo do Path2D
	var movimento_em_pixels = velocidade * delta
	var tamanho_total = get_parent().curve.get_baked_length()
	if tamanho_total > 0:
		progress_ratio += movimento_em_pixels / tamanho_total
	else:
		print("Erro: Caminho tem tamanho 0!")
	
	# Espelhar sprite
	if sprite:
		var angulo_graus = rotation_degrees
		while angulo_graus > 180: angulo_graus -= 360
		while angulo_graus < -180: angulo_graus += 360
		sprite.flip_v = abs(angulo_graus) > 90

	# Verifica se chegou ao fim do caminho (progress_ratio vai de 0.0 a 1.0)
	# Verifica se chegou ao fim do caminho (progress_ratio vai de 0.0 a 1.0)
	if progress_ratio >= 1.0:
		# 1. Aplica o dano diretamente no GameManager (que verifica o Game Over)
		game_manager.base_hp -= dano_na_floresta
		
		# 2. IMPORTANTE: Avisa o Gerenciador de Ondas que o inimigo "saiu" da conta
		# Enviamos 0 de recompensa porque o jogador não matou ele
		morreu.emit(0) 
		
		print("Inimigo chegou na base! Dano aplicado.")
		queue_free() # Inimigo some

func receber_dano(quantidade: float) -> void:
	vida_atual -= quantidade
	if barra_vida:
		barra_vida.visible = true
		barra_vida.value = vida_atual
	if vida_atual <= 0:
		morrer()

func morrer() -> void:
	game_manager.add_money(recompensa_sementes)
	if floating_text_scene:
		var float_instance = floating_text_scene.instantiate()
		float_instance.text_value = "+ $" + str(recompensa_sementes)
		float_instance.global_position = global_position
		get_tree().get_root().add_child(float_instance)
	morreu.emit(recompensa_sementes)
	queue_free()
