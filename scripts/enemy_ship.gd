extends Area2D

# Enemy ship properties
var speed = 150
var health = 50
var max_health = 50  # Added max_health
var explosion_radius = 100

# Movement properties
var velocity = Vector2.ZERO
var max_turn_rate = 3.5  # Ditingkatkan agar lebih responsif
var acceleration = 300
var friction = 0.98

# References
@onready var health_bar = $HealthBar
@onready var player_ref = null

# References for wake effects
@onready var wake_effect = $WakeEffect
@onready var wake_effect_2 = $WakeEffect2
var current_velocity = Vector2.ZERO

func _ready():
	add_to_group("enemies")
	connect("area_entered", Callable(self, "_on_area_entered"))

	# Initialize health bar
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health
	
	# Initialize wake effects
	if wake_effect:
		wake_effect.emitting = false
	if wake_effect_2:
		wake_effect_2.emitting = false
		
	# Find the player immediately upon spawning
	find_player()

func _process(delta):
	var prev_pos = global_position

	if player_ref == null:
		find_player()
		if player_ref == null:
			# Jika tidak ada player, bergerak lurus ke depan
			var forward_dir = Vector2(cos(rotation), sin(rotation))
			velocity += forward_dir * acceleration * delta
	else:
		# Langsung bergerak menuju player!
		charge_at_player(delta)
			
	# Apply movement
	position += velocity * delta
	
	# Apply friction
	velocity *= friction
	
	# Calculate velocity
	current_velocity = (global_position - prev_pos) / delta
	
	# Update wake effects
	update_wake_effect()

func find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]

func charge_at_player(delta):
	if !player_ref:
		return
		
	var direction = (player_ref.global_position - global_position).normalized()
	
	# Koreksi rotasi MINIMAL, karena sudah diarahkan saat spawn
	var target_angle = direction.angle()
	var angle_diff = fmod((target_angle - rotation + PI), (2 * PI)) - PI
	
	# Lebih cepat berputar ke arah player
	rotation += sign(angle_diff) * min(abs(angle_diff), max_turn_rate * delta)
	
	# Selalu bergerak ke depan, tidak perlu kondisi alignment
	var forward_dir = Vector2(cos(rotation), sin(rotation))
	velocity += forward_dir * acceleration * delta
	
	# Limit maximum velocity
	if velocity.length() > speed:
		velocity = velocity.normalized() * speed

# Fungsi-fungsi lainnya tetap sama seperti sebelumnya
func take_damage(amount):
	health -= amount

	# Update health bar
	if health_bar:
		health_bar.value = health

	if health <= 0:
		explode()
	else:
		# Flash red when hit but not destroyed
		modulate = Color(1.5, 0.5, 0.5)
		await get_tree().create_timer(0.1).timeout
		modulate = Color(1, 1, 1)

func explode():
	print("Enemy ship explodes!")
	
	if player_ref and global_position.distance_to(player_ref.global_position) < explosion_radius:
		if player_ref.has_method("take_damage"):
			player_ref.take_damage(30)
	
	queue_free()

func _on_area_entered(area):
	# Mengecek jika yang tersentuh adalah player ATAU enemy lain
	if area.is_in_group("player"):
		print("Kamikaze hit player!")
		if area.has_method("take_damage"):
			area.take_damage(30)
		explode()
	elif area.is_in_group("enemies") and area != self:
		# Pastikan bukan diri sendiri
		print("Enemy ships collided!")
		explode()

# Function to update wake effects
func update_wake_effect():
	# First, determine if we're moving fast enough to show wake
	var current_speed = current_velocity.length()
	var speed_ratio = current_speed / speed
	
	# Process first wake effect
	if wake_effect:
		if current_speed > 20:  # Lower threshold for better visual feedback
			wake_effect.emitting = true
			
			# Adjust amount based on speed
			wake_effect.amount = int(50 + speed_ratio * 100)
			
			# Adjust emission speed based on ship speed
			var material = wake_effect.process_material
			material.initial_velocity_min = 30 + speed_ratio * 70
			material.initial_velocity_max = 50 + speed_ratio * 150
			
			# NOTE: We don't need to set direction - using node rotation instead (-PI in scene)
		else:
			wake_effect.emitting = false
			
	# Process second wake effect
	if wake_effect_2:
		if current_speed > 20:
			wake_effect_2.emitting = true
			
			# Adjust amount based on speed
			wake_effect_2.amount = int(50 + speed_ratio * 100)
			
			# Adjust emission speed based on ship speed
			var material = wake_effect_2.process_material
			material.initial_velocity_min = 30 + speed_ratio * 70
			material.initial_velocity_max = 50 + speed_ratio * 150
			
			# NOTE: We don't need to set direction - using node rotation instead (-PI in scene)
		else:
			wake_effect_2.emitting = false
