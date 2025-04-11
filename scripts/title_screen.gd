extends Control

func _ready():
    # Pastikan tombol start terfokus saat scene dimuat
    $MarginContainer/VBoxContainer/StartButton.grab_focus()

func _on_start_button_pressed():
    # Pindah ke scene Main_Bg saat tombol ditekan
    get_tree().change_scene_to_file("res://scenes/Main_Bg.tscn")