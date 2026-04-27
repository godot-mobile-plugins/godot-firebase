#
# © 2026-present https://github.com/firebase-team
#

@tool
@icon("icon.png")
class_name Firebase extends Node

var auth: FirebaseAuth


func _ready() -> void:
	child_entered_tree.connect(_on_child_entered)
	child_exiting_tree.connect(_on_child_exiting)


func _on_child_entered(child: Node) -> void:
	match child:
		FirebaseAuth:
			if auth != null:
				if auth != child:
					GmpLogger.log_warn(
						"Multiple FirebaseAuth nodes detected. Only one FirebaseAuth node is supported at a time."
					)
				else:
					GmpLogger.log_warn("Tracked FirebaseAuth node readded.")
			else:
				auth = child


func _on_child_exiting(child: Node) -> void:
	match child:
		FirebaseAuth:
			if auth == child:
				auth = null
			else:
				GmpLogger.log_warn(
					"A FirebaseAuth node is exiting, but it does not match the currently tracked FirebaseAuth node."
				)


func count_children_of_type(parent: Node, type_to_find) -> int:
	var count = 0
	for child in parent.get_children():
		if is_instance_of(child, type_to_find):
			count += 1
	return count


func _get_configuration_warnings() -> PackedStringArray:
	var warnings = []

	var _auth_count = count_children_of_type(self, FirebaseAuth)
	if _auth_count > 1:
		warnings.append(
			"%d FirebaseAuth nodes detected. Only one FirebaseAuth node is supported at a time." % _auth_count
		)
	elif _auth_count == 0:
		warnings.append(
			(
				"No FirebaseAuth node detected. Please add a FirebaseAuth node as a child of this "
				+ "Firebase node to use authentication features."
			)
		)

	return warnings
