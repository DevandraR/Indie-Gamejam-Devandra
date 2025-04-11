extends Node2D

@onready var turret_barrel = $TurretBarrel
@onready var bullet_scene = $Bullet  # Reference to the bullet scene for duplication

# Turret properties
var rotation_speed = 1.5  # How quickly the turret turns
var detection_range = 800  # How far the turret can see
var attack_range = 600    # How far the turret can shoot

# Shooting properties
var can_shoot = true
var shoot_cooldown = 2.0  # Longer cooldown than player for balance
var bullet_speed = 600    # Slightly slower bullets than player
var accuracy = 30.0       # Random spread (higher = less accurate)

# Target tracking
var target_position = Vector2.ZERO
var player_ref = null     # Reference to player ship

# Define the "no-fire zone" angles (angles where the turret would hit the enemy ship)
var no_fire_start_angle = PI * 0.7
var no_fire_end_angle = PI * 1.3

func _ready():
	# Hide the original bullet instance (we'll use it as a template)
	if bullet_scene:
		bullet_scene.visible = false
	
	# Set up process
	set_process(true)

func _process(delta):
	# Try to find player if not already found
	if player_ref == null:
		find_player()
		return
	
	# Check if player is within detection range
	var distance_to_player = global_position.distance_to(player_ref.global_position)
	
	if distance_to_player <= detection_range:
		# Calculate direction to player
		var direction = player_ref.global_position - global_position
		
		# Calculate the target angle
		var target_angle = direction.angle()
		
		# Smoothly rotate towards the target angle
		var current_angle = rotation
		var angle_diff = fmod((target_angle - current_angle + 3 * PI), (2 * PI)) - PI
		rotation += sign(angle_diff) * min(abs(angle_diff), rotation_speed * delta)
		
		# Save target position for shooting
		target_position = player_ref.global_position
		
		# Check if we can fire
		var can_fire = check_firing_arc() and distance_to_player <= attack_range
		
		# Try to shoot if within range
		if can_fire and can_shoot:
			shoot()

func find_player():
	# Look for player in the scene - requires player to be in "player" group
	var potential_players = get_tree().get_nodes_in_group("player")
	if potential_players.size() > 0:
		player_ref = potential_players[0]

# Check if the turret is pointing in a valid direction
func check_firing_arc():
	# Convert rotation to a normalized angle between 0 and 2π
	var normalized_angle = fmod(rotation, 2 * PI)
	if normalized_angle < 0:
		normalized_angle += 2 * PI
	
	# Check if angle is in the no-fire zone
	return not (normalized_angle >= no_fire_start_angle and normalized_angle <= no_fire_end_angle)

# Function to shoot a bullet
func shoot():
	if not can_shoot or not bullet_scene:
		return
	
	# Create a new bullet instance from the template
	var new_bullet = bullet_scene.duplicate()
	
	# Add bullet to the root scene to avoid movement issues
	get_tree().root.add_child(new_bullet)
	
	# Calculate the barrel end position in global coordinates
	var barrel_end = global_position + Vector2(turret_barrel.position.x, 0).rotated(rotation)
	new_bullet.global_position = barrel_end
	new_bullet.visible = true
	
	# Add some random spread for less accuracy
	var random_spread = Vector2(randf_range(-accuracy, accuracy), randf_range(-accuracy, accuracy))
	var target_with_spread = target_position + random_spread
	
	# Calculate direction vector with spread
	var direction = (target_with_spread - barrel_end).normalized()
	
	# Set bullet velocity and rotation
	new_bullet.velocity = direction * bullet_speed
	new_bullet.rotation = direction.angle() + PI/2  # Adjust rotation to match sprite orientation
	new_bullet.target_position = target_with_spread
	new_bullet.speed = bullet_speed
	
	# Implement cooldown
	can_shoot = false
	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true
