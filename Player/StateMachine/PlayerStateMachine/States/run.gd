extends Motion

func _enter() -> void:
	print(name)

func _state_input(event: InputEvent) -> void:
	if event.is_action_pressed("Jump"):
		finished.emit("Jump")
		return

	if event.is_action_pressed("Sprint"):
		finished.emit("Sprint")
		return

	if event.is_action_pressed("Aim"):
		finished.emit("AimWalk")
		return

func _update(delta: float) -> void:
	set_direction()
	calculate_velocity(SPEED, direction, delta)

	if not is_on_floor():
		finished.emit("Fall")
		return

	if Input.is_action_pressed("Aim"):
		finished.emit("AimWalk")
		return

	if direction == Vector3.ZERO:
		finished.emit("Idle")
