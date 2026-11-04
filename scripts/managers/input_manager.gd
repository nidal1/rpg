## InputManager
## Manages global input handling and cursor states.
class_name InputManager
extends Node

# ─── Constants ───────────────────────────────────────────────────────────────
var arrow_cursor = load("res://assets/ui/UI Elements/UI Elements/Cursors/Cursor_01.png")
var pointing_cursor = load("res://assets/ui/UI Elements/UI Elements/Cursors/Cursor_02.png")
var forbidden_cursor = load("res://assets/ui/UI Elements/UI Elements/Cursors/Cursor_03.png")

# ─── Public Methods ──────────────────────────────────────────────────────────
## Initializes custom mouse cursors.
func initialize_cursors() -> void:
	Input.set_custom_mouse_cursor(arrow_cursor)
	Input.set_custom_mouse_cursor(pointing_cursor, Input.CURSOR_POINTING_HAND)
	Input.set_custom_mouse_cursor(forbidden_cursor, Input.CURSOR_FORBIDDEN)
