extends Path2D
class_name GerenciadorDeOndas

signal wave_iniciada(numero_wave: int)
signal wave_concluida()
signal vitoria_total()

# Usaremos Resources para configurar as waves, igual à referência
@export var cenas_inimigos: Array[PackedScene]
@export var lista_de_waves: Array[Wave] 
@export var tempo_entre_waves: float = 5.0

var wave_atual_index: int = -1
var inimigos_vivos: int = 0
var spawnando: bool = false

func _ready() -> void:
	# Inicia a primeira wave após um pequeno delay
	print("TAMANHO DO CAMINHO: ", curve.get_baked_length())
	await get_tree().create_timer(2.0).timeout
	iniciar_proxima_wave()

func iniciar_proxima_wave() -> void:
	wave_atual_index += 1
	
	if wave_atual_index >= lista_de_waves.size():
		vitoria_total.emit()
		print("Todas as waves concluídas! A floresta está salva.")
		return
		
	var wave_dados = lista_de_waves[wave_atual_index]
	spawnando = true
	wave_iniciada.emit(wave_atual_index + 1)
	print("Iniciando Wave: ", wave_atual_index + 1)
	
	_processar_spawns(wave_dados)

func _processar_spawns(wave: Wave) -> void:
	# Itera sobre cada grupo de inimigos configurado na Wave
	for spawn_info in wave.spawns_inimigo:
		
		if spawn_info == null:
			continue
		
		var qtd = spawn_info.quantidade
		var intervalo = spawn_info.duracao / float(qtd) if qtd > 0 else 1.0
		
		for i in range(qtd):
			if not spawnando: break # Caso o jogo tenha acabado
			
			_spawnar_inimigo(spawn_info)
			await get_tree().create_timer(intervalo).timeout
			
	spawnando = false

func _spawnar_inimigo(spawn_info: SpawnInimigo) -> void:
	# Pega um inimigo aleatório da lista configurada no Resource
	var inimigo_tipo = spawn_info.pegar_inimigo_aleatorio() # Retorna o Enum ou Index
	
	# --- IMPORTANTE ---
	# Você precisará de um script simples (Cache) para converter esse ID na CENA (.tscn)
	# Ou, para simplificar agora, assuma que spawn_info já tem a cena:
	var cena_inimigo = _obter_cena_pelo_id(inimigo_tipo) 
	
	if cena_inimigo:
		var instancia = cena_inimigo.instantiate()
		add_child(instancia)
		inimigos_vivos += 1
		
		# Conecta o sinal de morte para saber quando a wave acaba
		if instancia.has_signal("tree_exited"):
			instancia.tree_exited.connect(_on_inimigo_saiu_da_cena)

func _on_inimigo_saiu_da_cena() -> void:
	# --- PROTEÇÃO NOVA ---
	# Se este nó não estiver mais na cena, para tudo para não dar erro.
	if not is_inside_tree():
		return
	# ---------------------

	inimigos_vivos -= 1
	
	if inimigos_vivos <= 0 and not spawnando:
		wave_concluida.emit()
		print("Wave concluída. Próxima em breve...")
		
		# Proteção extra antes de criar o timer
		if is_inside_tree():
			await get_tree().create_timer(tempo_entre_waves).timeout
			iniciar_proxima_wave()

# Função auxiliar temporária para testes (Você substituirá pelo seu Cache depois)
func _obter_cena_pelo_id(id: int) -> PackedScene:
	if id >= 0 and id < cenas_inimigos.size():
		return cenas_inimigos[id]
	return null
