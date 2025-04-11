extends CanvasLayer

@onready var health_bar = $MarginContainer/VBoxContainer/HealthBarContainer/HealthBar
@onready var timer_label = $MarginContainer/VBoxContainer/TimerLabel

func _ready():
    update_health(100, 100)  # Initialize health bar at full

func _process(_delta):
    update_timer()

func update_health(current_health, max_health):
    health_bar.max_value = max_health
    health_bar.value = current_health
    
    # Update color based on health percentage
    var health_percent = float(current_health) / max_health
    var bar_style = health_bar.get("theme_override_styles/fill")
    
    if health_percent < 0.25:
        bar_style.bg_color = Color(0.9, 0.1, 0.1)  # Red when low
    elif health_percent < 0.5:
        bar_style.bg_color = Color(0.9, 0.6, 0.1)  # Orange when medium
    else:
        bar_style.bg_color = Color(0.0, 0.75, 0.0)  # Green when high

func update_timer():
    if has_node("/root/GameManager"):
        timer_label.text = "Time: " + GameManager.format_time()