extends Node2D
class_name GuardinhaBase

# --- CONFIGURAÇÃO ---
@export_category("Características")
@export var alcance: float = 200.0
@export var dano: float = 10.0
@export var tempo_recarga_tiro: float = 1.0 # Cooldown entre ataques
@export var rotacao_velocidade: float = 15.0

@export_category("Visual e Som")
@export var sprite_turret: Sprite2D # A parte que gira
@export var som_tiro: AudioStream
@export var ponto_de_saida_tiro: Marker2D # Onde o projétil nasce (na ponta da arma)

@export_category("Nodes Necessários")
@export var area_detector: Area2D # O "olho" do guardinha

# --- VARIÁVEIS INTERNAS ---
var inimigos_na_mira: Array[Node2D] = []
var alvo_atual: Node2D = null
var pode_atirar: bool = true
var timer_recarga: Timer

func _ready() -> void:
	# Configura o Timer de tiro via código (igual à referência)
	timer_recarga = Timer.new()
	timer_recarga.wait_time = tempo_recarga_tiro
	timer_recarga.one_shot = true
	timer_recarga.timeout.connect(_on_recarga_completa)
	add_child(timer_recarga)
	
	# Conecta os sinais da Area2D para detectar Lenhadores/Mandrakes
	if area_detector:
		area_detector.area_entered.connect(_on_alvo_entrou)
		area_detector.area_exited.connect(_on_alvo_saiu)
		
		# Ajusta o tamanho do colisor baseada no alcance
		var colisao = area_detector.get_child(0)
		if colisao is CollisionShape2D and colisao.shape is CircleShape2D:
			colisao.shape.radius = alcance

func _physics_process(delta: float) -> void:
	# Se não tem ninguém na mira, não faz nada
	if not is_instance_valid(alvo_atual):
		# Tenta pegar o próximo da lista se o atual morreu/sumiu
		if inimigos_na_mira.size() > 0:
			alvo_atual = inimigos_na_mira[0]
		return

	_mirar_no_alvo(delta)
	
	if pode_atirar:
		_atacar()

func _mirar_no_alvo(delta: float) -> void:
	# Lógica de rotação suave igual à referência 
	var direcao = alvo_atual.global_position - global_position
	var angulo_desejado = direcao.angle()
	
	sprite_turret.rotation = lerp_angle(sprite_turret.rotation, angulo_desejado, rotacao_velocidade * delta)

func _atacar() -> void:
	pode_atirar = false
	timer_recarga.start()
	
	# Toca o som (usando o SoundManager se você tiver, ou simples play)
	if som_tiro:
		# SoundManager.play_sound(som_tiro) # Descomente se for usar o SoundManager
		pass

	# APLICA O DANO
	# Verificamos se o inimigo tem o método 'tomou_dano' (como no InimigoArea.gd [cite: 24])
	if alvo_atual.has_method("tomou_dano"):
		alvo_atual.tomou_dano(dano)
		print("Guardinha protegeu a floresta! Dano: ", dano)

func _on_recarga_completa() -> void:
	pode_atirar = true

# --- DETECÇÃO DE INIMIGOS ---
func _on_alvo_entrou(area: Area2D) -> void:
	# Adiciona à lista se for um inimigo
	if area.is_in_group("InimigoArea"): # Importante: Seus inimigos devem ter esse grupo
		inimigos_na_mira.append(area)
		if alvo_atual == null:
			alvo_atual = area

func _on_alvo_saiu(area: Area2D) -> void:
	if area in inimigos_na_mira:
		inimigos_na_mira.erase(area)
		
	if area == alvo_atual:
		alvo_atual = null
		if inimigos_na_mira.size() > 0:
			alvo_atual = inimigos_na_mira[0]
