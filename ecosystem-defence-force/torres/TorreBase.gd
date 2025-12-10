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
@export var ponto_de_saida_tiro: Marker2D 

@export_category("Combate")
@export var cena_projetil: PackedScene 

@export_category("Nodes Necessários")
@export var area_detector: Area2D 

# --- VARIÁVEIS INTERNAS ---
var inimigos_na_mira: Array[Node2D] = [] # Armazena as Areas (Hitboxes)
var alvo_atual: Node2D = null
var pode_atirar: bool = true
var timer_recarga: Timer

func _ready() -> void:
	timer_recarga = Timer.new()
	timer_recarga.wait_time = tempo_recarga_tiro
	timer_recarga.one_shot = true
	timer_recarga.timeout.connect(_on_recarga_completa)
	add_child(timer_recarga)
	
	if area_detector:
		area_detector.area_entered.connect(_on_alvo_entrou)
		area_detector.area_exited.connect(_on_alvo_saiu)
		var colisao = area_detector.get_child(0)
		if colisao is CollisionShape2D and colisao.shape is CircleShape2D:
			colisao.shape.radius = alcance

func _physics_process(delta: float) -> void:
	# 1. Limpeza de segurança: remove inimigos mortos/nulos da lista
	inimigos_na_mira = inimigos_na_mira.filter(func(x): return is_instance_valid(x))
	
	# 2. SELEÇÃO DE ALVO (Lógica "First")
	# Recalcula o melhor alvo a cada frame (ou quando não tiver alvo)
	alvo_atual = pegar_inimigo_mais_a_frente()
	
	# 3. Comportamento de combate
	if is_instance_valid(alvo_atual):
		_mirar_no_alvo(delta)
		if pode_atirar:
			_atacar()

# --- NOVA FUNÇÃO DE PRIORIDADE ---
func pegar_inimigo_mais_a_frente() -> Node2D:
	var melhor_candidato: Node2D = null
	var maior_progresso: float = -1.0
	
	for area_inimigo in inimigos_na_mira:
		# A lista contem a Area2D (Hitbox). O script de movimento está no Pai.
		var inimigo_pai = area_inimigo.get_parent()
		
		# Verifica se o pai é válido e tem a função de progresso
		if is_instance_valid(inimigo_pai) and inimigo_pai.has_method("obter_progresso_total"):
			var progresso = inimigo_pai.obter_progresso_total()
			
			if progresso > maior_progresso:
				maior_progresso = progresso
				melhor_candidato = area_inimigo # Miramos na Hitbox
				
	return melhor_candidato
# ---------------------------------

func _mirar_no_alvo(delta: float) -> void:
	var direcao = alvo_atual.global_position - global_position
	var angulo_desejado = direcao.angle()
	sprite_turret.rotation = lerp_angle(sprite_turret.rotation, angulo_desejado, rotacao_velocidade * delta)

func _atacar() -> void:
	if not cena_projetil or not ponto_de_saida_tiro:
		print("ERRO: Configure a 'cena_projetil' e o 'ponto_de_saida_tiro'")
		return

	pode_atirar = false
	timer_recarga.start()
	
	if som_tiro:
		pass # Tocar som

	var bala = cena_projetil.instantiate()
	get_tree().root.add_child(bala)
	# Passamos o alvo_atual (que é a Hitbox) para a bala perseguir
	bala.iniciar(ponto_de_saida_tiro.global_position, alvo_atual, dano)

func _on_recarga_completa() -> void:
	pode_atirar = true

# --- DETECÇÃO ---
func _on_alvo_entrou(area: Area2D) -> void:
	if area.is_in_group("InimigoArea"): 
		inimigos_na_mira.append(area)
		# Não definimos alvo_atual aqui. O _physics_process vai decidir quem é o melhor.

func _on_alvo_saiu(area: Area2D) -> void:
	if area in inimigos_na_mira:
		inimigos_na_mira.erase(area)
	
	if area == alvo_atual:
		alvo_atual = null
