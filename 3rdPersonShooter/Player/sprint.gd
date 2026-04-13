extends Motion

signal sprint_started
signal sprint_ended

func _enter() -> void:
	sprint_started.emit()
	print(name)
	
func _state_input(event: InputEvent) -> void:
	if event.is_action_pressed("Jump"):
		finished.emit("Jump")
	
	if event.is_action_released("Sprint"):
		sprint_ended.emit()
		finished.emit("Run")
		
	if event.is_action_pressed("Aim"):
		sprint_ended.emit()
		finished.emit("AimWalk")
		
func _update(delta: float) -> void:
	set_direction()
	calculate_velocity(SPRINT_SPEED, direction, delta)
	
	if direction == Vector3.ZERO:
		sprint_ended.emit()
		finished.emit("Idle")
