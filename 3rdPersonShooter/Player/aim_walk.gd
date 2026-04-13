extends Motion

signal aim_entered
signal aim_exited

func _enter() -> void:
	aim_entered.emit()
	print(name)

func _state_input(event: InputEvent) -> void:
	if event.is_action_pressed("Jump"):
		aim_exited.emit()
		finished.emit("Jump")
		return

	if event.is_action_pressed("Sprint"):
		aim_exited.emit()
		finished.emit("Sprint")
		return

	if event.is_action_released("Aim"):
		aim_exited.emit()
		if direction == Vector3.ZERO:
			finished.emit("Idle")
		else:
			finished.emit("Run")
		return

func _update(delta: float) -> void:
	set_direction()
	calculate_velocity(AIM_SPEED, direction, delta)

	if not is_on_floor():
		aim_exited.emit()
		finished.emit("Fall")
		return

	if not Input.is_action_pressed("Aim"):
		aim_exited.emit()
		if direction == Vector3.ZERO:
			finished.emit("Idle")
		else:
			finished.emit("Run")
		return

	if direction == Vector3.ZERO:
		finished.emit("AimIdle")
