extends LightOccluder2D

func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	self.visible = true
	self.occluder_light_mask = 1 

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	self.visible = false
	self.occluder_light_mask = 0
