extends Node2D
class_name FaseGerenciador

# Este script serve agora como o nó principal da fase (World.tscn),
# orquestrando a UI e o GameManager, sem gerenciar a lógica de construção.

# [VARS REMOVIDAS] sementes_iniciais, sementes_atuais, hud_construcao, slot_selecionado

# ==========================================================
# FUNÇÕES DE VIDA DO NÓ
# ==========================================================

func _ready() -> void:
	# A lógica de conexão com Slots e a visibilidade da HUD de Construção
	# foram removidas para evitar o erro "Could not find type SlotDeConstrucao".
	
	# Se precisar de alguma inicialização global da fase (ex: iniciar a música),
	# adicione aqui. Caso contrário, deixe apenas 'pass'.
	pass

func _process(delta: float) -> void:
	# Lógica de processamento por frame (ex: controle de pause), se necessário.
	pass

# ==========================================================
# FUNÇÕES OBSOLETAS REMOVIDAS
# ==========================================================

# A lógica de slots (ex: _on_slot_clicado) foi removida.
# A lógica de compra (ex: tentar_comprar_torre) foi movida para IconeTropa.gd.
