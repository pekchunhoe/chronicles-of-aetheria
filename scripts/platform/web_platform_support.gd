class_name WebPlatformSupport
extends Node
## Browser-only lifecycle hooks; native platforms keep their existing behavior.
signal pause_requested
var _document: JavaScriptObject
var _window: JavaScriptObject
var _visibility_callback: JavaScriptObject
var _blur_callback: JavaScriptObject


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not OS.has_feature("web"):
		return
	_document = JavaScriptBridge.get_interface("document")
	_window = JavaScriptBridge.get_interface("window")
	_visibility_callback = JavaScriptBridge.create_callback(_on_visibility_changed)
	_blur_callback = JavaScriptBridge.create_callback(_on_window_blur)
	_document.addEventListener("visibilitychange", _visibility_callback)
	_window.addEventListener("blur", _blur_callback)


func _exit_tree() -> void:
	if _document != null:
		_document.removeEventListener("visibilitychange", _visibility_callback)
	if _window != null:
		_window.removeEventListener("blur", _blur_callback)


func _on_visibility_changed(_arguments: Array) -> void:
	if bool(_document.hidden):
		pause_requested.emit()


func _on_window_blur(_arguments: Array) -> void:
	pause_requested.emit()


static func is_touch_device() -> bool:
	if not OS.has_feature("web"):
		return false
	return bool(JavaScriptBridge.eval("navigator.maxTouchPoints > 0 || window.matchMedia('(pointer: coarse)').matches"))
