class_name PlayerInput
extends RefCounted

## The input/ layer's device reader (plan §7.1): translates keyboard + gamepad
## into an abstract PlayerIntent. It is the ONLY place that touches Godot's
## Input singleton; everything else consumes PlayerIntent.
##
## Actions are registered programmatically (ensure_actions) so project.godot
## stays free of hand-authored event dictionaries and gamepad support comes for
## free. Registration is idempotent and safe to call every construction.

const ACT_LEFT := "gn_move_left"
const ACT_RIGHT := "gn_move_right"
const ACT_UP := "gn_move_up"
const ACT_DOWN := "gn_move_down"
const ACT_INTERACT := "gn_interact"
const ACT_CANCEL := "gn_cancel"


func _init() -> void:
	ensure_actions()


## Registers the movement/interact actions if they are not already present.
static func ensure_actions() -> void:
	_add_action(ACT_LEFT, [_key(KEY_A), _key(KEY_LEFT), _joy_axis(JOY_AXIS_LEFT_X, -1.0)])
	_add_action(ACT_RIGHT, [_key(KEY_D), _key(KEY_RIGHT), _joy_axis(JOY_AXIS_LEFT_X, 1.0)])
	_add_action(ACT_UP, [_key(KEY_W), _key(KEY_UP), _joy_axis(JOY_AXIS_LEFT_Y, -1.0)])
	_add_action(ACT_DOWN, [_key(KEY_S), _key(KEY_DOWN), _joy_axis(JOY_AXIS_LEFT_Y, 1.0)])
	_add_action(ACT_INTERACT, [_key(KEY_E), _key(KEY_SPACE), _joy_button(JOY_BUTTON_A)])
	_add_action(ACT_CANCEL, [_key(KEY_ESCAPE), _joy_button(JOY_BUTTON_B)])


## Reads current device state into a fresh PlayerIntent. `interact_pressed` uses
## an edge (just-pressed) so a held button rides an elevator only once.
func poll() -> PlayerIntent:
	var intent: PlayerIntent = PlayerIntent.new()
	intent.move = Input.get_vector(ACT_LEFT, ACT_RIGHT, ACT_UP, ACT_DOWN)
	intent.interact_pressed = Input.is_action_just_pressed(ACT_INTERACT)
	intent.cancel_pressed = Input.is_action_just_pressed(ACT_CANCEL)
	return intent


# --- action registration helpers -------------------------------------------

static func _add_action(name: StringName, events: Array) -> void:
	if not InputMap.has_action(name):
		InputMap.add_action(name)
	for event: InputEvent in events:
		InputMap.action_add_event(name, event)


static func _key(keycode: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = keycode
	return e


static func _joy_axis(axis: JoyAxis, direction: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = direction
	return e


static func _joy_button(button: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = button
	return e
