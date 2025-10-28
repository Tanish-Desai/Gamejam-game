extends CharacterBody2D

const SPEED = 130.0
const JUMP_VELOCITY = -300.0
const TURN_ACCELERATION = 1900.0
const ROLL_SPEED = 220.0

@onready var Anim = $AnimatedSprite2D
@onready var roll_cooldown_timer = $Timer

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var direction_stack = []
var is_rolling = false
var current_roll_direction = 0 #Remembers which way we are rolling (1 for right, -1 for left).

func _input(event):
	var is_left = event.is_action("ui_left")
	var is_right = event.is_action("ui_right")

	if not is_left and not is_right:
		return

	var direction_value = 1 if is_right else -1

	if event.is_pressed():
		if not direction_value in direction_stack:
			direction_stack.push_back(direction_value)
	
	if event.is_released():
		direction_stack.erase(direction_value)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	var direction = direction_stack.back() if not direction_stack.is_empty() else 0

	if is_rolling:
		#ROLL CANCEL
		
		if Input.is_action_just_pressed("up_key") and is_on_floor():
			is_rolling = false
			velocity.y = JUMP_VELOCITY
		if direction != 0 and direction == -current_roll_direction:
			is_rolling = false
			velocity.x = direction * SPEED
			
	else:
		#NORMAL STATE
		
		if Input.is_action_just_pressed("up_key") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		if direction:
			if direction * velocity.x < 0:
				velocity.x = move_toward(velocity.x, direction * SPEED, TURN_ACCELERATION * delta)
			else:
				velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, TURN_ACCELERATION * delta)
			
		if Input.is_action_just_pressed("dodge_roll") and roll_cooldown_timer.is_stopped():
			is_rolling = true
			current_roll_direction = 1 if not Anim.flip_h else -1
			velocity.x = current_roll_direction * ROLL_SPEED
			if is_on_floor():
				velocity.y = 0
			Anim.play("roll")
			roll_cooldown_timer.start()

	#UNIVERSAL ANIMATION & FLIPPING
	
	if direction == -1:
		Anim.flip_h = true
	elif direction == 1:
		Anim.flip_h = false

	if is_rolling:
		if Anim.animation != "roll":
			Anim.play("roll")
	else:
		if not is_on_floor():
			Anim.play("Jump")
		else:
			if direction:
				Anim.play("run")
			else:
				Anim.play("idle")

	move_and_slide()

func _on_animated_sprite_2d_animation_finished():
	if Anim.animation == "roll":
		is_rolling = false
		velocity.x = 0
