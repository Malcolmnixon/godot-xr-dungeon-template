extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	GameState.health_changed.connect(_on_health_changed)
	GameState.gold_changed.connect(_on_gold_changed)
	$HealthBar.value = GameState.health
	$GoldValue.text = str(GameState.gold)


func _on_health_changed(p_health : int) -> void:
	$HealthBar.value = p_health

func _on_gold_changed(p_gold : int) -> void:
	$GoldValue.text = str(p_gold)
