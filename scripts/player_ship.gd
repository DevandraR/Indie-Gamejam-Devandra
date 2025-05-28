extends Area2D

# Movement parameters
var max_speed = 500     # Maximum speed
var acceleration = 150  # Increased for better responsiveness
var steering_speed = 2.0  # How quickly the ship turns while moving
var friction = 0.98     # Reduced friction slightly for less drag
var velocity = Vector2.ZERO
var current_speed = 0   # Track the current forward/backward speed

var max_health = 100
var current_health = 100

# Speed-up system
var max_energy = 100
var current_energy = 100
var energy_drain_rate = 25.0  # Energy per second when boosting
var energy_recovery_rate = 15.0  # Energy per second when not boosting
var boost_multiplier = 2.0  # Speed multiplier when boosting
var is_boosting = false

# Camera reference
@onready var camera = $Camera2D
@onready var wake_effect = $WakeEffect
@onready var wake_effect_2 = $WakeEffect2

func _ready():
	# Add to player group for enemy detection
	add_to_group("player")

	# Start game timer
	if has_node("/root/GameManager"):
		GameManager.start_game()
	
	if camera:
		# Enable smoothing for more natural camera movement
		camera.position_smoothing_enabled = true
		camera.rotation_smoothing_enabled = true

		camera.zoom = Vector2(0.5, 0.5)

	if wake_effect:
		wake_effect.emitting = false

	if wake_effect_2:
		wake_effect_2.emitting = false

func _physics_process(delta):
	# Get steering input (only affects rotation when moving)
	var steering_input = 0
	
	if Input.is_action_pressed("ui_left"):
		steering_input -= 1
	if Input.is_action_pressed("ui_right"):
		steering_input += 1
	
	# Handle acceleration/deceleration
	var acceleration_input = 0
	if Input.is_action_pressed("ui_up"):
		acceleration_input += 1
	if Input.is_action_pressed("ui_down"):
		acceleration_input -= 1
	
	# Handle speed boost
	is_boosting = Input.is_action_pressed("boost") and acceleration_input > 0 and current_energy > 0

	# Update energy
	if is_boosting:
		current_energy -= energy_drain_rate * delta
		current_energy = max(0, current_energy)
	else:
		current_energy += energy_recovery_rate * delta
		current_energy = min(max_energy, current_energy)

	# Calculate effective speed multiplier
	var speed_multiplier = boost_multiplier if is_boosting else 1.0
	var effective_max_speed = max_speed * speed_multiplier
	var effective_acceleration = acceleration * speed_multiplier

	# Apply acceleration in the forward/backward direction
	current_speed += acceleration_input * effective_acceleration * delta
	current_speed = clamp(current_speed, -effective_max_speed/2, effective_max_speed) # Backward is slower
	
	# Apply steering (only when moving)
	if abs(current_speed) > 10:
		if current_speed < 0:
			steering_input *= -1
		var turn_rate = steering_input * steering_speed * (abs(current_speed) / effective_max_speed) * delta
		rotation += turn_rate
	
	# Apply friction/drag
	if acceleration_input == 0:
		current_speed *= 0.97  # Stronger slowdown when not accelerating
	else:
		current_speed *= friction
	
	# Convert speed and rotation to velocity - FIXED DIRECTION
	# IMPORTANT: Change this vector to match your ship sprite's orientation
	# If ship points right: use Vector2(1, 0)
	# If ship points down: use Vector2(0, 1)
	# If ship points left: use Vector2(-1, 0)
	# If ship points up: use Vector2(0, -1)
	var forward_dir = Vector2(1, 0).rotated(rotation)  # Assuming ship points right
	velocity = forward_dir * current_speed
	
	# Move the ship
	position += velocity * delta

	# Update wake effect
	update_wake_effect()

	# Update HUD
	update_hud()
	
	# Debug display
	#print("Speed: ", current_speed, " Rotation: ", rotation)

func update_hud():
	var hud = get_node_or_null("/root/MainBg/HUD")
	if hud:
		hud.update_health(current_health, max_health)
		hud.update_energy(current_energy, max_energy)

# Add take_damage function
func take_damage(amount):
	current_health -= amount
	print("Player took damage: " + str(amount) + ", health now: " + str(current_health))
	
	# Update UI health bar
	var hud = get_node_or_null("/root/MainBg/HUD")
	if hud:
		hud.update_health(current_health, max_health)
	
	# More intense visual feedback
	modulate = Color(2.0, 0.3, 0.3)  # More intense red
	await get_tree().create_timer(0.15).timeout
	modulate = Color(1, 1, 1)  # Back to normal
	
	# Check if player is destroyed
	if current_health <= 0:
		destroy()
# Handle player destruction
func destroy():
	# End game timer
	if has_node("/root/GameManager"):
		GameManager.end_game()
	
	# Change to game over scene
	get_tree().change_scene_to_file("res://scenes/GameOver.tscn")
	
	# Optional: could add explosion effect before scene change

# Control the wake effect based on ship speed and direction
func update_wake_effect():
	if wake_effect:
		# Only show wake when moving at a decent speed
		var speed_ratio = abs(current_speed) / max_speed
		
		if abs(current_speed) > 50:
			wake_effect.emitting = true
			
			# Adjust amount based on speed
			wake_effect.amount = int(50 + speed_ratio * 100)
			
			# Adjust emission speed based on ship speed
			var material = wake_effect.process_material
			material.initial_velocity_min = 30 + speed_ratio * 70
			material.initial_velocity_max = 50 + speed_ratio * 150
			
		else:
			wake_effect.emitting = false

	if wake_effect_2:
		# Only show wake when moving at a decent speed
		var speed_ratio = abs(current_speed) / max_speed
		
		if abs(current_speed) > 50:
			wake_effect_2.emitting = true
			
			# Adjust amount based on speed
			wake_effect_2.amount = int(50 + speed_ratio * 100)
			
			# Adjust emission speed based on ship speed
			var material = wake_effect_2.process_material
			material.initial_velocity_min = 30 + speed_ratio * 70
			material.initial_velocity_max = 50 + speed_ratio * 150
			
		else:
			wake_effect_2.emitting = false
