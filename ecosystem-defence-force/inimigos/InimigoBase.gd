extends PathFollow2D
class_name InimigoBase

signal morreu(recompensa: int)
signal causou_dano_na_base(dano: int)

@export_category("Atributos")
@export var nome_inimigo: String = "Lenhador"
@export var velocidade: float = 100.0
@export var vida_maxima: float = 50.0
@export var dano_na_floresta: int = 1 # Quanto de vida tira da sua base
@export var recompensa_sementes: int = 5 # Dinheiro ganho ao derrotar

@export_category("Visual")
@export var sprite: AnimatedSprite2D
@export var barra_vida: ProgressBar
@export var floating_text_scene: PackedScene

@onready var game_manager = get_node("/root/GameManager")

var vida_atual: float

func _ready() -> void:
	vida_atual = vida_maxima
	
	# INÍCIO DA ANIMAÇÃO ---
	if sprite:
		sprite.play("andar")
	# ---------------------
	
	# Configura a barra de vida (opcional)
	if barra_vida:
		barra_vida.max_value = vida_maxima
		barra_vida.value = vida_atual
		barra_vida.visible = false # Só mostra quando tomar dano

func _physics_process(delta: float) -> void:
	# Movimentação ao longo do Path2D
	print("Pai: ", get_parent().name, " | Vel: ", velocidade, " | Progresso: ", progress)
	var movimento_em_pixels = velocidade * delta
	var tamanho_total = get_parent().curve.get_baked_length()

	if tamanho_total > 0:
		progress_ratio += movimento_em_pixels / tamanho_total
	else:
		print("Erro: Caminho tem tamanho 0!")
	
	# Espelhar o sprite (Flip H) dependendo da direção
	# Se a rotação do PathFollow for > 90 graus ou < -90, ele está indo para a esquerda
	if sprite:
		var angulo_graus = rotation_degrees
		# Normaliza o ângulo para ficar entre -180 e 180
		while angulo_graus > 180: angulo_graus -= 360
		while angulo_graus < -180: angulo_graus += 360
		
		# Se estiver olhando para a esquerda, flipa o sprite
		sprite.flip_v = abs(angulo_graus) > 90

	# Verifica se chegou ao fim do caminho (progress_ratio vai de 0.0 a 1.0)
	if progress_ratio >= 1.0:
		causou_dano_na_base.emit(dano_na_floresta)
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
	
	#retorno visual do ganho de dinheiro
	if floating_text_scene:
		var float_instance = floating_text_scene.instantiate()
		
		float_instance.text_value = "+ $" + str(recompensa_sementes)
		float_instance.global_position = global_position
		
		get_tree().get_root().add_child(float_instance)
	
	morreu.emit(recompensa_sementes)
	# Aqui você pode instanciar uma animação de explosão ou partículas de folhas
	queue_free()
