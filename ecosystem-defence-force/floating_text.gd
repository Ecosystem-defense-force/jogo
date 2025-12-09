extends Node2D

@export var txt_label: Label
@export var lifetime: float = 1.0
@export var anim_player: AnimationPlayer

var text_value: String = ""

func _ready():
		
	if is_instance_valid(txt_label):
		txt_label.text = text_value
		txt_label.pivot_offset = txt_label.size / 2
	
	if is_instance_valid(anim_player):
		anim_player.play("FloatAndFade")	
		
	await get_tree().create_timer(lifetime).timeout
	queue_free()
	
