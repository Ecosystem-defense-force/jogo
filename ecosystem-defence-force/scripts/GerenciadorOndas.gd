extends Path2D
class_name GerenciadorDeOndas

# 1. Tabela de Recompensas por Finalização de Onda (0 = Wave 1, etc.)
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
		
		# Lógica de Dificuldade Progressiva (Mantido o cálculo do colega/HEAD):
		var inimigos_extras = wave_atual_index * multiplicador_dificuldade
		var qtd_total = spawn_info.quantidade + inimigos_extras
		
		var intervalo = spawn_info.duracao / float(qtd_total) if qtd_total > 0 else 1.0
		
		for i in range(qtd_total):
			if not is_inside_tree(): return
			
			_spawnar_inimigo(spawn_info)
			await get_tree().create_timer(intervalo).timeout
			
	spawnando = false
	
	# Edge Case: Força a verificação se todos os inimigos morreram antes do spawn terminar
	if inimigos_vivos == 0:
		_finalizar_wave()

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
	inimigos_vivos += 1
	
	# Conexão de sinais com funções anônimas (Lambdas - Solução do Henrique)
	instancia.morreu.connect(func(_recompensa):
		_on_inimigo_saiu_da_cena() # Chama a função sem argumento para evitar erro
	)
	
	instancia.causou_dano_na_base.connect(func(dano):
		if game_manager:
			game_manager.base_hp -= dano
		_on_inimigo_saiu_da_cena()
	)

func _on_inimigo_saiu_da_cena() -> void:
	if not is_inside_tree(): return

	inimigos_vivos -= 1
	
	# Se a contagem chegar a zero e não houver mais spawn, finaliza
	if inimigos_vivos <= 0 and not spawnando:
		_finalizar_wave()

func _finalizar_wave() -> void:
	# LÓGICA DE BÔNUS (Mantida a sua versão HEAD):
	if wave_atual_index < WAVE_BONUS_TABLE.size():
		var bonus = WAVE_BONUS_TABLE[wave_atual_index]
		
		# Crédito do dinheiro ao jogador
		game_manager.add_money(bonus)
		
		print("BÔNUS DE WAVE CREDITADO: ", bonus)
	
	# FIM DA LÓGICA DE BÔNUS
	
	wave_concluida.emit()
	
	if is_inside_tree():
		await get_tree().create_timer(tempo_entre_waves).timeout
		iniciar_proxima_wave()

# Retorna a cena baseada no ID configurado no Resource
func _obter_cena_pelo_id(id: int) -> PackedScene:
	if id >= 0 and id < cenas_inimigos.size():
		return cenas_inimigos[id]
	return null
