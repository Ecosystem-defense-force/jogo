extends CanvasLayer
@export var lbl_hp_base: Label
@export var lbl_onda_atual: Label
@export var lbl_dinheiro: Label


# Called when the node enters the scene tree for the first time.
func _ready():
	var game_manager = get_node("/root/GameManager")
	
	#conecta as funções de atualização aos sinais do gamemanager
	game_manager.base_hp_changed.connect(self._update_base_hp)
	game_manager.wave_changed.connect(self._update_wave)
	game_manager.money_changed.connect(self._update_money)
	
	#atualiza a jud com os valores atuais
	_update_base_hp(game_manager.base_hp)
	_update_wave(game_manager.current_wave)
	_update_money(game_manager.player_money)
	
#funções de atualização
func _update_base_hp(new_hp_amount: int):
	lbl_hp_base.text = "Base HP: " + str(new_hp_amount)
	
func _update_wave(new_wave_number: int):
	lbl_onda_atual.text = "Onda: " + str(new_wave_number)

func _update_money(new_money_amount: int):
	# Formata o dinheiro (ex: $500)
	lbl_dinheiro.text = "$" + str(new_money_amount)
