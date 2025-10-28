extends CharacterBody2D

const SPEED = 100.0
const TURN_ACCELERATION = 1200.0
const ROLL_SPEED = 160.0

# --- NEW JUMP CONSTANTS ---
# This is the constant upward speed of the "jetpack" jump.
const JUMP_SPEED = 140.0 
# This is the max duration (in seconds) the jump "jetpack" can be active.
const JUMP_DURATION = 0.15
# This is the terminal velocity, or max fall speed.
const MAX_FALL_SPEED = 500.0 
# --- OLD JUMP CONSTANTS REMOVED ---

@onready var Anim = $AnimatedSprite2D
@onready var roll_cooldown_timer = $Timer

# Using a floaty gravity for the fall
var gravity = 980
var direction_stack = []
var is_rolling = false
var current_roll_direction = 0

# --- NEW JUMP STATE VARIABLES ---
var is_jumping = false # True when the "jetpack" is active
var jump_time_elapsed = 0.0 # How long the jetpack has been on

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
	
	# --- NEW JETPACK JUMP & GRAVITY LOGIC ---
	
	# 1. Apply gravity *first*.
	# We only apply gravity if we are NOT actively jetpacking upwards.
	if not is_jumping:
		velocity.y += gravity * delta

	# 2. Start the jump (on floor).
	if Input.is_action_just_pressed("up_key") and is_on_floor():
		is_jumping = true
		jump_time_elapsed = 0.0
	
	# 3. Stop the jump (when key is released). This creates the short hop.
	if Input.is_action_just_released("up_key"):
		is_jumping = false
		
	# 4. Handle the "jetpack" logic while in the air.
	if is_jumping:
		# Check if we still have "fuel" in our jump.
		if jump_time_elapsed < JUMP_DURATION:
			# Set a constant upward speed, overriding gravity.
			velocity.y = -JUMP_SPEED 
			jump_time_elapsed += delta
		else:
			# Jump duration ran out, stop the jetpack.
			is_jumping = false
			
	# 5. Clamp fall speed (Terminal Velocity).
	velocity.y = min(velocity.y, MAX_FALL_SPEED)
	
	# --- END OF NEW LOGIC ---

	var direction = direction_stack.back() if not direction_stack.is_empty() else 0

	if is_rolling:
		#ROLL CANCEL
		if Input.is_action_just_pressed("up_key") and is_on_floor():
			is_rolling = false
			is_jumping = true # Start a new jump
			jump_time_elapsed = 0.0
		if direction != 0 and direction == -current_roll_direction:
			is_rolling = false
			velocity.x = direction * SPEED
	else:
		#NORMAL STATE
		
		# (Jump logic is now at the top of the function)

		# Horizontal Movement
		if direction:
			if direction * velocity.x < 0:
				velocity.x = move_toward(velocity.x, direction * SPEED, TURN_ACCELERATION * delta)
			else:
				velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, TURN_ACCELERATION * delta)
		
		# Start Roll
		if Input.is_action_just_pressed("dodge_roll") and roll_cooldown_timer.is_stopped():
			is_rolling = true
			is_jumping = false # Can't jump and roll
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
