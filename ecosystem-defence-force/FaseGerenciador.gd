extends Node2D

@export var sementes_iniciais: int = 50
@onready var sementes_atuais: int = sementes_iniciais

# Interface (HUD) que vamos controlar
@onready var hud_construcao: CanvasLayer = $HUD 

# Guarda qual Slot o jogador clicou por último
var slot_selecionado: SlotDeConstrucao = null

func _ready() -> void:
	# Esconde o menu de botões no começo
	if hud_construcao:
		hud_construcao.visible = false
	
	# Conecta o sinal de TODOS os slots que estiverem na fase
	for slot in get_tree().get_nodes_in_group("Slots"):
		slot.slot_clicado.connect(_on_slot_clicado)

func _on_slot_clicado(slot: SlotDeConstrucao) -> void:
	# Se o slot já tem torre, talvez mostrar opções de upgrade (futuro)
	if slot.torre_construida != null:
		print("Esse slot já está ocupado.")
		return

	# 1. Guarda quem é o slot alvo
	slot_selecionado = slot
	
	# 2. Move o menu para perto do slot (opcional, ou deixa fixo na tela)
	# hud_construcao.global_position = slot.global_position 
	
	# 3. Mostra o menu de botões
	hud_construcao.visible = true
	print("Menu aberto para o slot: ", slot.name)

# Esta função é chamada pelo BOTÃO do HUD
func tentar_comprar_torre(dados: DadosTorre) -> void:
	if slot_selecionado == null:
		return
		
	if sementes_atuais >= dados.preco:
		# Paga e Constrói
		sementes_atuais -= dados.preco
		slot_selecionado.construir(dados.cena_torre)
		
		# Fecha o menu e limpa a seleção
		hud_construcao.visible = false
		slot_selecionado = null
		print("Construído! Sementes restantes: ", sementes_atuais)
	else:
		print("Sem dinheiro!")
