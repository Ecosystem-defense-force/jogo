extends Node

signal base_hp_changed(new_hp_amount: int)
signal wave_changed(new_wave_number: int)
signal money_changed(new_money_amount: int)

var base_hp: int = 100:
	set(value):
		base_hp = max(0,value)
		base_hp_changed.emit(base_hp)
		
var player_money: int = 300:
	set(value):
		player_money = max(0,value)
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









	
