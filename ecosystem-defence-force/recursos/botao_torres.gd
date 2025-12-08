extends Button

@export var dados_da_torre: DadosTorre 

func _pressed() -> void:
	# Pega a cena atual (Fase1) e chama a função de compra
	var fase = get_tree().current_scene
	if fase.has_method("tentar_comprar_torre"):
		fase.tentar_comprar_torre(dados_da_torre)
