# game_over.gd
extends Control

@onready var survival_time_label = $VBoxContainer/SurvivalTimeLabel

func _ready():
    # Get and format the survival time from global game state
    var time = GameManager.get_survival_time() if has_node("/root/GameManager") else 0
    var minutes = int(time / 60)
    var seconds = int(time) % 60
    
    # Display formatted time
    survival_time_label.text = "You survived for: %02d:%02d" % [minutes, seconds]

func _on_restart_button_pressed():
    # Return to title screen
    get_tree().change_scene_to_file("res://scenes/Title_Screen.tscn")