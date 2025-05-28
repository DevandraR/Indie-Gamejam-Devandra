extends Node2D

@onready var turret_barrel = $TurretBarrel
@onready var bullet_scene = $Bullet  # Reference to the bullet scene for duplication
var special_bullet_scene = preload("res://scenes/SpecialBullet.tscn")  # Special bullet

# Line properties
var draw_aim_line = true
var dot_spacing = 15
var dot_size = 3
var line_color = Color(1, 0, 0, 0.5)  # Semi-transparent red
var special_line_color = Color(1, 0.5, 0, 0.7)  # Orange for special bullets
var max_distance = 1000  # Maximum line length

# Shooting properties
var can_shoot = true
var can_shoot_special = true
var shoot_cooldown = 0.5  # Time between shots
var special_shoot_cooldown = 2.0  # Longer cooldown for special bullets
var bullet_speed = 800    # How fast bullets travel
var special_bullet_speed = 600
var can_fire_now = true   # Whether currently pointing in a valid direction

# Special ammo system
var special_ammo = 10
var max_special_ammo = 10
var ammo_regen_time = 8.0  # Seconds to regenerate 1 special ammo
var ammo_timer = 0.0

# Target position for the bullet to reach
var target_position = Vector2.ZERO

# Define the "no-fire zone" angles (angles where the turret would hit the ship)
# This represents the range of angles (in radians) where the turret points at the ship
var no_fire_start_angle = PI * 0.8 # About 108 degrees
var no_fire_end_angle = PI * 1.2    # About 252 degrees

func _ready():
    # Hide the original bullet instance (we'll use it as a template)
    if bullet_scene:
        bullet_scene.visible = false
    
    # Ensure we can draw
    set_process(true)

func _process(delta):
    # Regenerate special ammo over time
    if special_ammo < max_special_ammo:
        ammo_timer += delta
        if ammo_timer >= ammo_regen_time:
            ammo_timer = 0.0
            special_ammo += 1
            print("Special ammo regenerated: " + str(special_ammo) + "/" + str(max_special_ammo))

    # Get global mouse position
    var mouse_pos = get_global_mouse_position()
    
    # Calculate direction to mouse in global space
    var direction = mouse_pos - global_position
    
    # Calculate the raw angle to the mouse
    var raw_angle = direction.angle()
    
    # Set turret rotation, compensating for the ship's rotation
    # We need to subtract the parent's (ship's) rotation to get the correct local angle
    rotation = raw_angle - get_parent().rotation
    
    # Save target position for shooting
    target_position = mouse_pos
    
    # Determine if we can fire (not pointing at ship)
    check_firing_arc()
    
    # Update visual representation
    queue_redraw()
    
    # Check for shooting input
    if Input.is_action_just_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        if can_fire_now and can_shoot:
            shoot()
        else:
            # Optionally: play a "can't shoot" sound or show a visual indication
            print("Cannot fire! Turret pointing at ship.")

    elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
        if can_fire_now and can_shoot_special and special_ammo > 0:
            shoot_special()

# Check if the turret is pointing in a valid direction
func check_firing_arc():
    # Convert rotation to a normalized angle between 0 and 2π
    var normalized_angle = fmod(rotation, 2 * PI)
    if normalized_angle < 0:
        normalized_angle += 2 * PI
    
    # Check if angle is in the no-fire zone
    can_fire_now = not (normalized_angle >= no_fire_start_angle and normalized_angle <= no_fire_end_angle)
    
    # Change aim line color based on whether we can fire
    if can_fire_now:
        line_color = Color(1, 0, 0, 0.5)  # Red when can fire
    else:
        line_color = Color(0.7, 0.7, 0.7, 0.5)  # Gray when can't fire

func _draw():
    if draw_aim_line:
        # Use the barrel position as the starting point
        var barrel_tip = Vector2.ZERO
        
        # Get mouse position in local coordinates
        var local_mouse_pos = get_local_mouse_position()
        
        # Limit the maximum distance of the line if needed
        var direction = (local_mouse_pos - barrel_tip).normalized()
        var distance = barrel_tip.distance_to(local_mouse_pos)
        var target_pos = local_mouse_pos
        
        if distance > max_distance:
            target_pos = barrel_tip + direction * max_distance
        
        # Draw dotted line from barrel tip to mouse cursor
        draw_dotted_line(barrel_tip, target_pos, line_color, dot_size, dot_spacing)

# Draw a dotted line between two points with fixed spacing
func draw_dotted_line(from, to, color, dot_size, spacing):
    var direction = (to - from).normalized()
    var distance = from.distance_to(to)
    var current_pos = from
    
    # Draw dots along the line with proper spacing
    var steps = int(distance / spacing)
    
    for i in range(steps):
        draw_circle(current_pos, dot_size, color)
        current_pos += direction * spacing
    
    # Always draw the last dot exactly at the destination (mouse cursor)
    draw_circle(to, dot_size, color)

# Function to shoot a bullet
func shoot():
    if not can_shoot or not bullet_scene:
        return
    
    # Create a new bullet instance from the template
    var new_bullet = bullet_scene.duplicate()
    
    # Add bullet to the root scene (get_tree().root) instead of the parent
    get_tree().root.add_child(new_bullet)
    
    # Calculate the barrel end position in global coordinates
    var barrel_end = global_position + Vector2(turret_barrel.position.x, 0).rotated(rotation)
    new_bullet.global_position = barrel_end
    new_bullet.visible = true
    
    # Calculate direction vector
    var direction = (target_position - barrel_end).normalized()
    
    # Set bullet velocity and rotation
    new_bullet.velocity = direction * bullet_speed
    new_bullet.rotation = direction.angle() + PI/2  # Adjust rotation to match sprite orientation
    new_bullet.target_position = target_position
    new_bullet.speed = bullet_speed
    new_bullet.damage = 15
    
    # Implement cooldown
    can_shoot = false
    await get_tree().create_timer(shoot_cooldown).timeout
    can_shoot = true

# Set up bullet behavior
func setup_bullet(bullet):
    # Connect signals for area entered (collision)
    if bullet is Area2D:
        bullet.connect("area_entered", Callable(self, "_on_Bullet_area_entered").bind(bullet))
    
    # Start moving the bullet
    var direction = bullet.get_meta("direction")
    var speed = bullet.get_meta("speed")
    var target = bullet.get_meta("target_position")
    
    # Create a process function for the bullet
    bullet.set_process(true)
    bullet.set_meta("_process", func(delta):
        # Move bullet toward target
        var current_pos = bullet.global_position
        var move_distance = speed * delta
        bullet.global_position += direction * move_distance
        
        # Check if bullet reached target position
        if bullet.global_position.distance_to(target) < 10:
            explode_bullet(bullet)
    )

# Handle bullet explosion
func explode_bullet(bullet):
    # TODO: Add explosion effect here later
    print("Bullet exploded!")
    
    # Remove the bullet
    bullet.queue_free()

# Signal handler for bullet collision
func _on_Bullet_area_entered(area, bullet):
    # Check if bullet hit an enemy
    if area.is_in_group("enemies"):
        print("Hit enemy!")
        explode_bullet(bullet)

func shoot_special():
    if not can_shoot_special or special_ammo <= 0:
        return
    
    # Use special ammo
    special_ammo -= 1
    print("Special shot fired! Ammo remaining: " + str(special_ammo))
    
    var new_bullet = special_bullet_scene.instantiate()
    get_tree().root.add_child(new_bullet)
    
    var barrel_end = global_position + Vector2(turret_barrel.position.x, 0).rotated(rotation)
    new_bullet.global_position = barrel_end

    # SET SHOOTER REFERENCE 
    new_bullet.shooter = get_parent()  # Player ship sebagai shooter
    
    var direction = (target_position - barrel_end).normalized()
    new_bullet.velocity = direction * special_bullet_speed
    new_bullet.rotation = direction.angle() + PI/2
    new_bullet.target_position = target_position
    new_bullet.speed = special_bullet_speed
    
    can_shoot_special = false
    await get_tree().create_timer(special_shoot_cooldown).timeout
    can_shoot_special = true

# Get special ammo info for HUD
func get_special_ammo():
    return special_ammo

func get_max_special_ammo():
    return max_special_ammo