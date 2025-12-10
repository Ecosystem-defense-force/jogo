extends TextureRect

#variaveis de config
@export var troop_scene: PackedScene
@export var troop_cost: int = 100
@export var drag_ghost_scene: PackedScene

@onready var game_manager = get_node("/root/GameManager")

#constantes do mapa
const PLACEMENT_COLLISION_LAYER = 1
const OBSTACLE_COLLISION_LAYER = 2
const TILE_SIZE: int = 16        

#variaveis locais
var is_dragging = false
var ghost_instance: Area2D = null

#interação com o icone da hud (futura validação monetaria aqui!)
func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and not is_dragging:    
				#adicionar validação de preço aqui!!!!           
				start_drag()
			elif not event.pressed and is_dragging:               
				end_drag()

#começo do arrasto
func start_drag():
	is_dragging = true
	
	#instancia o dragghost
	ghost_instance = drag_ghost_scene.instantiate()
	
	#configuração do sprite do fantasma
	if ghost_instance.has_node("Sprite2D"):
		ghost_instance.get_node("Sprite2D").texture = texture
		
	get_tree().get_root().add_child(ghost_instance)
	
	
	ghost_instance.modulate = Color(1,1,1,0.6) #transparencia
	ghost_instance.z_index = 100 				 # garante que vai ficar por cima de tudo

#fantasma segue o mouse 
func _process(delta):
	if is_dragging and is_instance_valid(ghost_instance):
		# o fantasma segue o mouse
		var mouse_pos = get_global_mouse_position()
		
		var snapped_pos = Vector2(
			floor(mouse_pos.x / TILE_SIZE) * TILE_SIZE + TILE_SIZE / 2,
			floor(mouse_pos.y / TILE_SIZE) * TILE_SIZE + TILE_SIZE / 2
		)
		
		ghost_instance.global_position = snapped_pos

# fim do arrasto (com validação e instanciação)
func end_drag():
	is_dragging = false
	
	# remoção do fantasma do icone
	if not is_instance_valid(ghost_instance): return
	
	var world_node = get_tree().get_root().get_node_or_null("World")
	if not world_node: ghost_instance.queue_free(); return
	
	var tile_map =world_node.get_node_or_null("TileMap")
	if not tile_map: ghost_instance.queue_free(); return
	
	var snapped_pos = ghost_instance.global_position
	
	#validação monetaria
	if not game_manager.spend_money(troop_cost):
		ghost_instance.queue_free()
		print("Sem dinheiro!")
		return
			
	var space_state = tile_map.get_world_2d().direct_space_state
	
	var params = PhysicsPointQueryParameters2D.new()
	params.position = snapped_pos
	params.collide_with_bodies = true
	params.exclude = [ghost_instance.get_rid()]
	
	params.collision_mask = 1 << (OBSTACLE_COLLISION_LAYER - 1)
	var obstacle_found = space_state.intersect_point(params, 32)
	var has_obstacle = obstacle_found.size() > 0
	
	params.collision_mask = 1 << (PLACEMENT_COLLISION_LAYER - 1)
	var base_found = space_state.intersect_point(params, 32)
	var on_valid_base = base_found.size() > 0
	
	var is_occupied = false #implementação de espaço já ocupado 
	var is_valid_placement = on_valid_base and not has_obstacle and not is_occupied
	
	if is_valid_placement:
		var center_pos = snapped_pos
		
		var troop = troop_scene.instantiate()
		troop.global_position = center_pos
		world_node.add_child(troop)
		
		ghost_instance.queue_free()
	else:
		game_manager.add_money(troop_cost)
		ghost_instance.queue_free()
		
		
	
	
	
	
