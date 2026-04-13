extends Motion

func _enter() -> void:
	print(name)

func _state_input(event: InputEvent) -> void:
	if event.is_action_pressed("Jump"):
		finished.emit("Jump")
		return

	if event.is_action_pressed("Aim"):
		if Input.get_vector("Left", "Right", "Up", "Down") != Vector2.ZERO:
			finished.emit("AimWalk")
		else:
			finished.emit("AimIdle")
		return

func _update(delta: float) -> void:
	set_direction()
	calculate_velocity(AIM_SPEED, direction, delta)

	if not is_on_floor():
		finished.emit("Fall")
		return

	if Input.is_action_pressed("Aim"):
		if direction != Vector3.ZERO:
			finished.emit("AimWalk")
		else:
			finished.emit("AimIdle")
		return

	if direction != Vector3.ZERO:
		finished.emit("Run")
