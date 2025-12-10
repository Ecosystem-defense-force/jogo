extends Path2D
class_name GerenciadorDeOndas

# 1. Tabela de Recompensas por Finalização de Onda
const WAVE_BONUS_TABLE: Array[int] = [100, 150, 150, 200, 300] 

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
var spawnando: bool = false

# VARIÁVEIS DE CONTROLE DE FLUXO (NOVAS E ROBUSTAS)
var inimigos_spawnados_nesta_wave: int = 0
var inimigos_eliminados_nesta_wave: int = 0


func _ready() -> void:
	# Aguarda um momento inicial antes de começar a primeira wave
	await get_tree().create_timer(2.0).timeout
	iniciar_proxima_wave()

func iniciar_proxima_wave() -> void:
	# Reseta os contadores no início de cada nova wave
	inimigos_spawnados_nesta_wave = 0
	inimigos_eliminados_nesta_wave = 0
	
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
		var inimigos_extras = wave_atual_index * multiplicador_dificuldade
		var qtd_total = spawn_info.quantidade + inimigos_extras
		
		var intervalo = spawn_info.duracao / float(qtd_total) if qtd_total > 0 else 1.0
		
		for i in range(qtd_total):
			if not is_inside_tree(): return
			
			_spawnar_inimigo(spawn_info)
			
			# Incrementa a contagem de inimigos CRIADOS
			inimigos_spawnados_nesta_wave += 1
			
			await get_tree().create_timer(intervalo).timeout
			
	spawnando = false
	
	# NÃO É MAIS NECESSÁRIO forçar a verificação aqui.
	# A função _on_inimigo_saiu_da_cena fará a checagem final.
	
func _spawnar_inimigo(spawn_info: SpawnInimigo) -> void:
	var inimigo_tipo = spawn_info.pegar_inimigo_aleatorio()
	var cena_inimigo = _obter_cena_pelo_id(inimigo_tipo)
	
	if not cena_inimigo:
		return

	var instancia = cena_inimigo.instantiate()
	
	if not instancia.has_signal("morreu"):
		push_error("ERRO: O objeto instanciado '%s' não possui o sinal 'morreu'." % instancia.name)
		add_child(instancia)
		return

	add_child(instancia)
	
	# Conexão de sinais com Lambdas para evitar erro de assinatura e atualizar contagem
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

	# Incrementa a contagem de ELIMINADOS
	inimigos_eliminados_nesta_wave += 1
	
	print("ELIMINADOS: ", inimigos_eliminados_nesta_wave, " / SPAWNADOS: ", inimigos_spawnados_nesta_wave, " | SPAWNING: ", spawnando)
	
	# Condição de finalização:
	# 1. Todos que foram CRIADOS já foram ELIMINADOS
	# 2. O spawn de novos inimigos já terminou
	if inimigos_eliminados_nesta_wave >= inimigos_spawnados_nesta_wave and not spawnando:
		_finalizar_wave()

func _finalizar_wave() -> void:
	# LÓGICA DE BÔNUS:
	if wave_atual_index < WAVE_BONUS_TABLE.size():
		var bonus = WAVE_BONUS_TABLE[wave_atual_index]
		
		# Crédito do dinheiro ao jogador
		game_manager.add_money(bonus)
		
		print("BÔNUS DE WAVE CREDITADO: ", bonus)
	
	wave_concluida.emit()
	
	if is_inside_tree():
		await get_tree().create_timer(tempo_entre_waves).timeout
		iniciar_proxima_wave()

# Retorna a cena baseada no ID configurado no Resource
func _obter_cena_pelo_id(id: int) -> PackedScene:
	if id >= 0 and id < cenas_inimigos.size():
		return cenas_inimigos[id]
	return null
