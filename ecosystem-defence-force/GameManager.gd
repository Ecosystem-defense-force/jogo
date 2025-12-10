extends Node

signal base_hp_changed(new_hp_amount: int)
signal wave_changed(new_wave_number: int)
signal money_changed(new_money_amount: int)
signal game_won 

# --- CONFIGURAÇÕES INICIAIS (CONSTANTES) ---
# Se quiser mudar o balanceamento do jogo, mude AQUI.
const INITIAL_HP: int = 100
const INITIAL_MONEY: int = 300
const INITIAL_WAVE: int = 1

# --- CENAS ---
var game_over_scene: String = "res://tela_derrota.tscn"
var victory_scene: String = "res://tela_vitoria.tscn"

# --- VARIÁVEIS ---
# Iniciamos usando as constantes definidas acima
var base_hp: int = INITIAL_HP:
	set(value):
		base_hp = max(0, value)
		base_hp_changed.emit(base_hp)
		
		if base_hp == 0:
			trigger_game_over()

var player_money: int = INITIAL_MONEY:
	set(value):
		player_money = max(0, value)
		money_changed.emit(player_money)
		
var current_wave: int = INITIAL_WAVE:
	set(value):
		current_wave = value
		wave_changed.emit(current_wave)

# --- MÉTODOS ---

# Função nova para resetar o jogo
func reset_game() -> void:
	# Como usamos setters, ao mudar os valores aqui, 
	# os sinais (signals) serão emitidos automaticamente e atualizarão a UI.
	base_hp = INITIAL_HP
	player_money = INITIAL_MONEY
	current_wave = INITIAL_WAVE
	get_tree().paused = false # Garante que o jogo despausa se tiver pausado
	print("GameManager: Jogo resetado para os valores iniciais!")

func add_money(amount: int):
	player_money += amount

func spend_money(amount: int) -> bool:
	if player_money >= amount:
		player_money -= amount
		return true	
	return false

# --- GAME OVER ---
func trigger_game_over():
	print("--- INICIANDO GAME OVER ---")
	
	if FileAccess.file_exists(game_over_scene):
		print("Cena de Derrota encontrada! Trocando...")
		get_tree().paused = false 
		var resultado = get_tree().change_scene_to_file(game_over_scene)
		
		if resultado != OK:
			print("ERRO ao trocar para Derrota: ", resultado)
	else:
		print("ERRO CRÍTICO: Arquivo não existe: ", game_over_scene)

# --- VITÓRIA ---
func trigger_victory():
	print("--- INICIANDO VITÓRIA ---")
	game_won.emit() 
	
	if FileAccess.file_exists(victory_scene):
		print("Cena de Vitória encontrada! Trocando...")
		get_tree().paused = false 
		var resultado = get_tree().change_scene_to_file(victory_scene)
		
		if resultado != OK:
			print("ERRO ao trocar para Vitória: ", resultado)
	else:
		print("ERRO CRÍTICO: Arquivo não existe: ", victory_scene)
