extends Node

# Game state tracking
var game_time = 0
var is_game_running = false

func _ready():
    reset_game()

func _process(delta):
    if is_game_running:
        game_time += delta

func start_game():
    reset_game()
    is_game_running = true

func end_game():
    is_game_running = false

func reset_game():
    game_time = 0
    is_game_running = false
    
func get_survival_time():
    return game_time
    
func format_time():
    var minutes = int(game_time / 60)
    var seconds = int(game_time) % 60
    return "%02d:%02d" % [minutes, seconds]