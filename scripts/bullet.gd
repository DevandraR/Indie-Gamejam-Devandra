extends Area2D

var velocity = Vector2.ZERO
var target_position = Vector2.ZERO
var speed = 800
var damage = 15  # Added damage value

func _ready():
    # Connect to area_entered signal
    connect("area_entered", Callable(self, "_on_area_entered"))

func _process(delta):
    # Move toward target
    position += velocity * delta
    
    # Update rotation to match movement direction
    rotation = velocity.angle() + PI/2  # Add this line to update rotation
    
    # Check if we reached target position
    if global_position.distance_to(target_position) < 10:
        # Reached target, explode
        explode()

func explode():
    # Add explosion effect here later
    print("Bullet exploded!")
    queue_free()

func _on_area_entered(area):
    # Handle collision with enemies
    if area.is_in_group("enemies"):
        print("Hit enemy!")

        # Apply damage to enemy
        if area.has_method("take_damage"):
            area.take_damage(damage)

        explode()