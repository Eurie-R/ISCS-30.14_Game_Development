extends Motion

signal sprint_ended

func _update(delta : float) -> void:
	set_direction()
	calculate_gravity(delta)
	calculate_velocity(SPRINT_SPEED, direction, delta)
	
	if is_on_floor():
		set_direction()
		if Input.is_action_pressed("Sprint"):
			finished.emit("Sprint")
		elif direction != Vector3.ZERO:
			sprint_ended.emit( )
			finished.emit("Run")
		else:
			sprint_ended.emit()
			finished.emit("Idle")
