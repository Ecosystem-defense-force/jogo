extends Path2D
class_name GerenciadorDeOndas

# 1. Tabela de Recompensas por Finalização de Onda (MANTIDO DO HEAD)
const WAVE_BONUS_TABLE: Array[int] = [100, 150, 150, 200, 300] 

# Sinais para comunicar o estado do jogo para a UI ou GameManager
signal wave_iniciada(numero_wave: int)
signal wave_concluida()
signal vitoria_total()
# Novo sinal para a UI mostrar o tempo restante (opcional)
signal tempo_proxima_wave_iniciado(tempo_total: float)

@export_group("Configurações da Wave")
@export var cenas_inimigos: Array[PackedScene]
@export var lista_de_waves: Array[Wave] 
@export var tempo_entre_waves: float = 60.0 # Mantido o valor da feature
@export var multiplicador_dificuldade: int = 2

# Se TRUE, inicia a próxima wave assim que matar todos (sem esperar os 5s).
@export var inicio_imediato_automatico: bool = false 

@onready var game_manager = get_node("/root/GameManager")

# Variáveis Internas (MANTIDO DA FEATURE)
var wave_atual_index: int = -1
var spawnando: bool = false
var _timer_espera: Timer # Usando Timer real
var inimigos_vivos: int = 0 # REINTRODUZIDO PELA FEATURE!

# VARIÁVEIS DE CONTROLE DE FLUXO PARA GARANTIR A PROGRESSÃO
# NOTA: O código abaixo ainda depende de 'inimigos_vivos'
var inimigos_spawnados_nesta_wave: int = 0 # Reutilizada para contagem total

func _ready() -> void:
	# Criar o timer via código para ter controle total
	_timer_espera = Timer.new()
	_timer_espera.one_shot = true
	_timer_espera.timeout.connect(iniciar_proxima_wave)
	add_child(_timer_espera)

	print("Iniciando primeira wave em 2 segundos...")
	# Timer inicial curto
	_timer_espera.start(2.0)

func iniciar_proxima_wave() -> void:
	# Garante que o timer parou (caso tenha sido chamado manualmente)
	_timer_espera.stop() 
	
	wave_atual_index += 1
	
	if game_manager:
		game_manager.current_wave = wave_atual_index + 1
	
	if wave_atual_index >= lista_de_waves.size():
		vitoria_total.emit()
		return
		
	var wave_dados = lista_de_waves[wave_atual_index]
	spawnando = true
	wave_iniciada.emit(wave_atual_index + 1)
	
	_processar_spawns(wave_dados)

func _processar_spawns(wave: Wave) -> void:
	# Reseta os contadores no início de cada nova wave (AJUSTADO PARA A FEATURE)
	inimigos_spawnados_nesta_wave = 0
	
	for spawn_info in wave.spawns_inimigo:
		if spawn_info == null: continue
		
		var inimigos_extras = wave_atual_index * multiplicador_dificuldade
		var qtd_total = spawn_info.quantidade + inimigos_extras
		var intervalo = spawn_info.duracao / float(qtd_total) if qtd_total > 0 else 1.0
		
		for i in range(qtd_total):
			if not is_inside_tree(): return
			
			_spawnar_inimigo(spawn_info)
			
			# Contagem de inimigos CRIADOS
			inimigos_spawnados_nesta_wave += 1
			
			await get_tree().create_timer(intervalo).timeout
			
	spawnando = false
	
	# AJUSTE PÓS-MESCLAGEM: Se a contagem total de inimigos (spawnados)
	# for igual aos inimigos VIVOS (reintroduzido pela feature) e o spawn acabou,
	# finaliza a wave. Isso mitiga o bug de timing.
	if inimigos_spawnados_nesta_wave > 0 and inimigos_vivos == 0:
		_finalizar_wave()

func _spawnar_inimigo(spawn_info: SpawnInimigo) -> void:
	var inimigo_tipo = spawn_info.pegar_inimigo_aleatorio()
	var cena_inimigo = _obter_cena_pelo_id(inimigo_tipo)
	
	if not cena_inimigo: return

	var instancia = cena_inimigo.instantiate()
	
	if not instancia.has_signal("morreu"):
		push_error("ERRO: Inimigo sem sinal 'morreu'")
		add_child(instancia) 
		return 

	add_child(instancia)
	inimigos_vivos += 1 # O inimigo está vivo, incrementa o contador da feature
	
	# MANTIDO: Conexão de sinais com Lambdas (Solução à prova de falhas)
	instancia.morreu.connect(func(_recompensa):
		_on_inimigo_saiu_da_cena()
	)
	
	instancia.causou_dano_na_base.connect(func(dano):
		if game_manager:
			game_manager.base_hp -= dano
		_on_inimigo_saiu_da_cena()
	)

func _on_inimigo_saiu_da_cena() -> void:
	if not is_inside_tree(): return

	inimigos_vivos -= 1 # Decrementa o contador da feature
	
	# Condição de finalização:
	if inimigos_vivos <= 0 and not spawnando:
		_finalizar_wave()

func _finalizar_wave() -> void:
	# LÓGICA DE BÔNUS (MANTIDO DO HEAD):
	if wave_atual_index < WAVE_BONUS_TABLE.size():
		var bonus = WAVE_BONUS_TABLE[wave_atual_index]
		
		# Crédito do dinheiro ao jogador
		game_manager.add_money(bonus)
		
		print("BÔNUS DE WAVE CREDITADO: ", bonus)
	
	wave_concluida.emit()
	
	# LÓGICA DE TEMPORIZADOR (MANTIDO DA FEATURE):
	if inicio_imediato_automatico:
		print("Inimigos derrotados. Iniciando próxima wave imediatamente!")
		iniciar_proxima_wave()
	else:
		print("Wave concluída. Esperando ", tempo_entre_waves, " segundos...")
		tempo_proxima_wave_iniciado.emit(tempo_entre_waves)
		_timer_espera.start(tempo_entre_waves)

func pular_contagem() -> void:
	if _timer_espera.time_left > 0:
		print("Jogador pulou a espera!")
		_timer_espera.stop()
		iniciar_proxima_wave()

func _obter_cena_pelo_id(id: int) -> PackedScene:
	if id >= 0 and id < cenas_inimigos.size():
		return cenas_inimigos[id]
	return null