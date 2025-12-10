extends Node

signal base_hp_changed(new_hp_amount: int)
signal wave_changed(new_wave_number: int)
signal money_changed(new_money_amount: int)

# Caminho da sua cena de derrota (Certifique-se que o nome do arquivo é exato)
var game_over_scene: String = "res://tela_derrota.tscn"

var base_hp: int = 100:
	set(value):
		base_hp = max(0, value)
		base_hp_changed.emit(base_hp)
		print("GameManager: Vida alterada para ", base_hp) # DEBUG
		
		if base_hp == 0:
			trigger_game_over()

var player_money: int = 300:
	set(value):
		player_money = max(0, value)
		money_changed.emit(player_money)
		
var current_wave: int = 1:
	set(value):
		current_wave = value
		wave_changed.emit(current_wave)

func add_money(amount: int):
	player_money += amount

func spend_money(amount: int) -> bool:
	if player_money >= amount:
		player_money -= amount
		return true	
	return false

func trigger_game_over():
	print("--- INICIANDO GAME OVER ---")
	
	# Verifica se o arquivo existe de verdade
	if FileAccess.file_exists(game_over_scene):
		print("Cena encontrada! Trocando agora...")
		
		# Tenta trocar a cena
		var resultado = get_tree().change_scene_to_file(game_over_scene)
		
		if resultado != OK:
			print("ERRO: O Godot não conseguiu trocar a cena. Código de erro: ", resultado)
	else:
		print("ERRO CRÍTICO: O arquivo não existe no caminho: ", game_over_scene)
		print("Verifique se o nome é exatamente 'tela_derrota.tscn' e se está na raiz (res://)")
