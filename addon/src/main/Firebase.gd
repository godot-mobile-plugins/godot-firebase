#
# © 2026-present https://github.com/firebase-team
#

@tool
@icon("icon.png")
class_name Firebase extends Node

var auth: FirebaseAuth
var firestore: Firestore


func _ready() -> void:
	for child in get_children():
		_process_discovered_child(child)

	child_entered_tree.connect(_on_child_entered)
	child_exiting_tree.connect(_on_child_exiting)


func _on_child_entered(child: Node) -> void:
	_process_discovered_child(child)


func _process_discovered_child(child: Node) -> void:
	if child is FirebaseModule:
		if child is FirebaseAuth:
			if auth == null:
				GmpLogger.log_info("Firebase Authentication node set.")
				auth = child
			else:
				if auth != child:
					GmpLogger.log_warn(
						"Multiple FirebaseAuth nodes detected. Only one FirebaseAuth node is supported at a time."
					)
				else:
					GmpLogger.log_warn("Tracked FirebaseAuth node readded.")
		elif child is Firestore:
			if firestore == null:
				GmpLogger.log_info("Firebase Firestore node set.")
				firestore = child
			else:
				if firestore == child:
					GmpLogger.log_warn("Tracked Firestore node readded.")
				else:
					GmpLogger.log_warn(
						"Multiple Firestore nodes detected. Only one Firestore node is supported at a time."
					)
		else:
			GmpLogger.log_error(
				(
					"Child node of type %s is a FirebaseModule but does not match any handled module types."
					% child.get_class()
				)
			)


func _on_child_exiting(child: Node) -> void:
	if child is FirebaseModule:
		if child is FirebaseAuth:
			if auth == child:
				auth = null
			else:
				GmpLogger.log_warn(
					"A FirebaseAuth node is exiting, but it does not match the currently tracked FirebaseAuth node."
				)
		elif child is Firestore:
			if firestore == child:
				firestore = null
			else:
				GmpLogger.log_warn(
					"A Firestore node is exiting, but it does not match the currently tracked Firestore node."
				)
		else:
			GmpLogger.log_error(
				(
					"Child node of type %s is a FirebaseModule but does not match any handled module types."
					% child.get_class()
				)
			)


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

	var _firestore_count = count_children_of_type(self, Firestore)
	if _firestore_count > 1:
		warnings.append(
			"%d Firestore nodes detected. Only one Firestore node is supported at a time." % _firestore_count
		)

	return warnings


func count_children_of_type(parent: Node, type_to_find) -> int:
	var count = 0
	for child in parent.get_children():
		if is_instance_of(child, type_to_find):
			count += 1
	return count
