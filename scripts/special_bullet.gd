extends Area2D

var velocity = Vector2.ZERO
var target_position = Vector2.ZERO
var speed = 600  # Lebih lambat dari bullet biasa
var damage = 25  # Damage direct hit
var splash_radius = 150  # Radius splash damage
var splash_damage = 15  # Damage untuk area sekitar
var shooter = null  # Referensi ke yang menembak

func _ready():
    connect("area_entered", Callable(self, "_on_area_entered"))

func _process(delta):
    # Move toward target
    position += velocity * delta
    
    # Update rotation to match movement direction
    rotation = velocity.angle() + PI/2
    
    # Check if we reached target position
    if global_position.distance_to(target_position) < 15:
        explode_with_splash()

func explode_with_splash():
    print("Special bullet exploded with splash damage!")
    
    # Apply splash damage to all enemies in radius
    var enemies = get_tree().get_nodes_in_group("enemies")
    for enemy in enemies:
        var distance = global_position.distance_to(enemy.global_position)
        if distance <= splash_radius:
            if enemy.has_method("take_damage"):
                # Damage berkurang seiring jarak
                var damage_multiplier = 1.0 - (distance / splash_radius)
                var final_damage = int(splash_damage * damage_multiplier)
                enemy.take_damage(final_damage)
                print("Splash damage: " + str(final_damage) + " to enemy at distance " + str(distance))
    
    # TODO: Tambahkan efek visual explosion di sini
    queue_free()

func _on_area_entered(area):
	# IGNORE shooter - jangan mengenai yang menembak
    if area == shooter:
        return
	
    # Handle direct hit
    if area.is_in_group("enemies"):
        print("Special bullet direct hit!")
        if area.has_method("take_damage"):
            area.take_damage(damage)
        explode_with_splash()
    elif area.is_in_group("player"):
        print("Special bullet hit player!")
        if area.has_method("take_damage"):
            area.take_damage(damage)
        explode_with_splash()