extends Node2D
@onready var timer = $Timer
func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
#		Added a slo-mo effect
		Engine.time_scale = 0.5
		body.death()
		timer.start()

func _on_timer_timeout():
	Engine.time_scale = 1
	get_tree().reload_current_scene()
