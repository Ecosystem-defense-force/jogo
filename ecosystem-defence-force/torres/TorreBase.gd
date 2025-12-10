extends Node2D
class_name GuardinhaBase

# --- CONFIGURAÇÃO ---
@export_category("Características")
@export var alcance: float = 200.0
@export var dano: float = 10.0
@export var tempo_recarga_tiro: float = 1.0 
@export var rotacao_velocidade: float = 15.0

@export_category("Visual e Som")
@export var sprite_turret: Sprite2D 
@export var som_tiro: AudioStream
@export var ponto_de_saida_tiro: Marker2D # <--- ESSENCIAL: Onde a bala nasce

@export_category("Combate")
@export var cena_projetil: PackedScene # <--- NOVO: Onde colocaremos o projetil.tscn

@export_category("Nodes Necessários")
@export var area_detector: Area2D 

# --- VARIÁVEIS INTERNAS ---
var inimigos_na_mira: Array[Node2D] = []
var alvo_atual: Node2D = null
var pode_atirar: bool = true
var timer_recarga: Timer

func _ready() -> void:
	# Criação do timer via código (mantive seu original)
	timer_recarga = Timer.new()
	timer_recarga.wait_time = tempo_recarga_tiro
	timer_recarga.one_shot = true
	timer_recarga.timeout.connect(_on_recarga_completa)
	add_child(timer_recarga)
	
	if area_detector:
		area_detector.area_entered.connect(_on_alvo_entrou)
		area_detector.area_exited.connect(_on_alvo_saiu)
		
		# Ajusta o colisor visualmente
		var colisao = area_detector.get_child(0)
		if colisao is CollisionShape2D and colisao.shape is CircleShape2D:
			colisao.shape.radius = alcance

func _physics_process(delta: float) -> void:
	# Validação do alvo
	if not is_instance_valid(alvo_atual):
		if inimigos_na_mira.size() > 0:
			# Remove nulos da lista antes de pegar o próximo
			inimigos_na_mira = inimigos_na_mira.filter(func(x): return is_instance_valid(x))
			if inimigos_na_mira.size() > 0:
				alvo_atual = inimigos_na_mira[0]
		return

	_mirar_no_alvo(delta)
	
	if pode_atirar:
		_atacar()

func _mirar_no_alvo(delta: float) -> void:
	var direcao = alvo_atual.global_position - global_position
	var angulo_desejado = direcao.angle()
	sprite_turret.rotation = lerp_angle(sprite_turret.rotation, angulo_desejado, rotacao_velocidade * delta)

func _atacar() -> void:
	if not cena_projetil or not ponto_de_saida_tiro:
		print("ERRO: Configure a 'cena_projetil' e o 'ponto_de_saida_tiro' no Inspector!")
		return

	pode_atirar = false
	timer_recarga.start()
	
	if som_tiro:
		pass # Tocar som

	# --- AQUI MUDA TUDO: CRIAMOS A BALA ---
	var bala = cena_projetil.instantiate()
	
	# Adicionamos a bala na Raiz do Jogo (World) e não dentro da torre
	# Isso impede que a bala gire junto com a torre ou suma se a torre for vendida
	get_tree().root.add_child(bala)
	
	# Configuramos a bala usando a função que criamos no Passo 1
	bala.iniciar(ponto_de_saida_tiro.global_position, alvo_atual, dano)

func _on_recarga_completa() -> void:
	pode_atirar = true

# --- DETECÇÃO ---
func _on_alvo_entrou(area: Area2D) -> void:
	if area.is_in_group("InimigoArea"): 
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
