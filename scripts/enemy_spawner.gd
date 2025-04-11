extends Node

# Enemy spawning properties
var enemy_scene = preload("res://scenes/Enemy_Ship.tscn")
var spawn_timer = 0
var min_spawn_time = 3.0    # Lebih cepat (dari 5.0)
var max_spawn_time = 8.0    # Lebih cepat (dari 12.0)
var max_enemies = 8         # Lebih banyak (dari 5)
var min_spawn_radius = 1500
var max_spawn_radius = 2000
var spawn_count = 0

# Difficulty scaling
var difficulty_timer = 0
var difficulty_increase_interval = 30.0  # Tingkatkan kesulitan setiap 30 detik
var max_difficulty_level = 5

# Reference to player
var player = null

func _ready():
    await get_tree().create_timer(2.0).timeout
    spawn_enemy()

func _process(delta):
    if player == null:
        var players = get_tree().get_nodes_in_group("player")
        if players.size() > 0:
            player = players[0]
            
    # Tingkatkan kesulitan seiring waktu
    difficulty_timer += delta
    if difficulty_timer >= difficulty_increase_interval:
        difficulty_timer = 0
        increase_difficulty()

func spawn_enemy():
    if player != null:
        var current_enemies = get_tree().get_nodes_in_group("enemies").size()
        
        if current_enemies < max_enemies:
            # Random angle around player
            var spawn_angle = randf() * 2 * PI
            var spawn_distance = randf_range(min_spawn_radius, max_spawn_radius)
            
            # Calculate spawn position
            var spawn_pos = player.global_position + Vector2(
                cos(spawn_angle) * spawn_distance,
                sin(spawn_angle) * spawn_distance
            )
            
            # Create enemy instance
            var enemy = enemy_scene.instantiate()
            enemy.global_position = spawn_pos
            
            # PENTING: Set rotasi awal agar menghadap player
            var direction = (player.global_position - spawn_pos).normalized()
            enemy.rotation = direction.angle()
            
            # Tambahkan ke scene
            get_parent().add_child(enemy)
            
            # Stats tracking
            spawn_count += 1
    
    # Schedule next spawn
    var next_spawn_time = randf_range(min_spawn_time, max_spawn_time)
    await get_tree().create_timer(next_spawn_time).timeout
    spawn_enemy()

# Tingkatkan kesulitan game seiring waktu
func increase_difficulty():
    # Tingkatkan jumlah maksimum musuh
    if max_enemies < 12:  # Cap at 12 enemies max
        max_enemies += 1
        
    # Kurangi waktu spawn
    if min_spawn_time > 1.5:
        min_spawn_time -= 0.3
    if max_spawn_time > 5.0:
        max_spawn_time -= 0.5
        
    print("Difficulty increased! Max enemies: " + str(max_enemies) + 
          ", Spawn time: " + str(min_spawn_time) + "-" + str(max_spawn_time))