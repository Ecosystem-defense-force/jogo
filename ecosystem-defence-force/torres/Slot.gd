extends Area2D
class_name SlotDeConstrucao

# O Slot avisa para o mundo: "Ei, clicaram em mim!"
signal slot_clicado(slot_proprio)

var torre_construida: Node2D = null

func _input_event(_viewport, event, _shape_idx):
	# Detecta clique do botão esquerdo no Slot
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("Slot clicado!")
		slot_clicado.emit(self)

func construir(cena_torre: PackedScene):
	# Instancia a torre AQUI dentro
	var nova_torre = cena_torre.instantiate()
	add_child(nova_torre) # A torre vira filha do Slot
	torre_construida = nova_torre
