extends Path2D
class_name GerenciadorDeOndas

# Sinais para comunicar o estado do jogo para a UI ou GameManager
signal wave_iniciada(numero_wave: int)
signal wave_concluida()
signal vitoria_total()

# Configurações de Wave e Inimigos
@export_group("Configurações da Wave")
@export var cenas_inimigos: Array[PackedScene]
@export var lista_de_waves: Array[Wave] 
@export var tempo_entre_waves: float = 5.0
@export var multiplicador_dificuldade: int = 2 # Quantos inimigos extras por wave

@onready var game_manager = get_node("/root/GameManager")

# Variáveis de Estado Interno
var wave_atual_index: int = -1
var inimigos_vivos: int = 0
var spawnando: bool = false

func _ready() -> void:
	# Aguarda um momento inicial antes de começar a primeira wave
	await get_tree().create_timer(2.0).timeout
	iniciar_proxima_wave()

func iniciar_proxima_wave() -> void:
	wave_atual_index += 1
	
	# Atualiza o GameManager (Index + 1 para exibição correta "Wave 1")
	if game_manager:
		game_manager.current_wave = wave_atual_index + 1 
	
	# Verifica condição de vitória
	if wave_atual_index >= lista_de_waves.size():
		vitoria_total.emit()
		return
		
	var wave_dados = lista_de_waves[wave_atual_index]
	spawnando = true
	wave_iniciada.emit(wave_atual_index + 1)
	
	_processar_spawns(wave_dados)

func _processar_spawns(wave: Wave) -> void:
	# Itera sobre cada grupo de configuração de spawn
	for spawn_info in wave.spawns_inimigo:
		
		if spawn_info == null: continue
		
		# Lógica de Dificuldade Progressiva:
		# Adiciona inimigos extras baseado no número da wave atual
		var inimigos_extras = wave_atual_index * multiplicador_dificuldade
		var qtd_total = spawn_info.quantidade + inimigos_extras
		
		# Evita divisão por zero
		var intervalo = spawn_info.duracao / float(qtd_total) if qtd_total > 0 else 1.0
		
		for i in range(qtd_total):
			if not is_inside_tree(): return 
			
			_spawnar_inimigo(spawn_info)
			await get_tree().create_timer(intervalo).timeout
			
	spawnando = false 
	
	# Edge Case: Se todos os inimigos morreram ANTES do spawn terminar,
	# o sinal de morte não disparou a próxima wave. Forçamos a verificação aqui.
	if inimigos_vivos == 0:
		_finalizar_wave()

func _spawnar_inimigo(spawn_info: SpawnInimigo) -> void:
	var inimigo_tipo = spawn_info.pegar_inimigo_aleatorio()
	var cena_inimigo = _obter_cena_pelo_id(inimigo_tipo) 
	
	if not cena_inimigo:
		return

	var instancia = cena_inimigo.instantiate()
	
	# Adiciona o inimigo como filho do Path2D (GerenciadorOndas)
	add_child(instancia)
	
	# Verifica se o script InimigoBase está carregado corretamente
	if not instancia is InimigoBase and not instancia.has_signal("morreu"):
		push_error("ERRO CRÍTICO: O inimigo spawnado não tem o script 'InimigoBase' anexado! Verifique a cena: " + instancia.name)
		return

	inimigos_vivos += 1
	
	# Conecta APENAS o sinal de morte.
	# A lógica de dano já é feita pelo próprio inimigo antes de emitir esse sinal.
	instancia.morreu.connect(func(_recompensa):
		_on_inimigo_saiu_da_cena()
	)

func _on_inimigo_saiu_da_cena() -> void:
	if not is_inside_tree(): return

	inimigos_vivos -= 1
	
	# Só finaliza a wave se não estivermos mais spawnando ninguém
	if inimigos_vivos <= 0 and not spawnando:
		_finalizar_wave()

func _finalizar_wave() -> void:
	wave_concluida.emit()
	
	if is_inside_tree():
		await get_tree().create_timer(tempo_entre_waves).timeout
		iniciar_proxima_wave()

# Retorna a cena baseada no ID configurado no Resource
func _obter_cena_pelo_id(id: int) -> PackedScene:
	if id >= 0 and id < cenas_inimigos.size():
		return cenas_inimigos[id]
	return null
