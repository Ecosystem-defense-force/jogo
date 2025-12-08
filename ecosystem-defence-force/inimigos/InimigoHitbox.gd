extends Area2D
class_name InimigoHitbox

# Quando o Guardinha atira, ele chama essa função
func tomou_dano(dano: float) -> void:
	# Repassa o dano para o script principal do Inimigo (o Pai)
	var inimigo_pai = get_parent()
	if inimigo_pai.has_method("receber_dano"):
		inimigo_pai.receber_dano(dano)

func chegou_ao_final() -> void:
	# O inimigo sai do mapa (destrói o objeto pai)
	get_parent().queue_free()
