extends Node2D
@onready var timer = $Timer
func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		body.death()
		timer.start()

func _on_timer_timeout():
	get_tree().reload_current_scene()
