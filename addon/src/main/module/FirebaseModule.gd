#
# © 2026-present https://github.com/firebase-team
#

@tool
@abstract
class_name FirebaseModule extends Node

const PLUGIN_SINGLETON_NAME: String = "@pluginName@"

var _plugin_singleton: Object


func _ready() -> void:
	_update_plugin()


func _notification(a_what: int) -> void:
	if a_what == NOTIFICATION_APPLICATION_RESUMED:
		_update_plugin()


func _update_plugin() -> void:
	if _plugin_singleton == null:
		if Engine.has_singleton(PLUGIN_SINGLETON_NAME):
			_plugin_singleton = Engine.get_singleton(PLUGIN_SINGLETON_NAME)
			_connect_signals()
		elif not Engine.is_editor_hint():
			GmpLogger.log_error("%s singleton not found on this platform!" % PLUGIN_SINGLETON_NAME)


@abstract func _connect_signals() -> void


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []

	var parent = get_parent()
	if not parent is Firebase:
		warnings.append("This node must be a child of a Firebase node to function properly.")

	return warnings
