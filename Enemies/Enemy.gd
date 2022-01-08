extends Node2D

export (int) var health = 1
export (int) var damage = 1
export (int) var defense = 1
export (int) var speed = 1
export (int) var level = 1

onready var animation = $Sprite/AnimationPlayer

signal enemy_attack(damage)
signal enemy_death()
signal attack_finished()
signal turn_completed()

func _ready():
	animation.play("Idle")

func play_turn():
	attack()
	print(1)
	return self

func attack():
	animation.play("Attack")
	yield(get_tree().create_timer(.55), "timeout")
	animation.queue("Idle")
	emit_signal("enemy_attack", damage)

func _on_player_attack(player_damage):
	health -= player_damage
	if health <= 0:
		animation.play("Dying")
		emit_signal("enemy_death")
	else:
		animation.play("Hurt")
		yield(get_tree().create_timer(.6), "timeout")
		animation.queue("Idle")
