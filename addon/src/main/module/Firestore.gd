#
# © 2026-present https://github.com/firebase-team
#

@tool
@icon("../icon.png")
class_name Firestore extends FirebaseModule

signal document_written(result: FirestoreDocument)
signal document_write_failed(error: FirestoreError)
signal document_updated(result: FirestoreDocument)
signal document_update_failed(error: FirestoreError)
signal document_deleted(result: FirestoreDocument)
signal document_delete_failed(error: FirestoreError)
signal document_changed(document: FirestoreDocument)
signal document_query_completed(result: FirestoreDocument)
signal document_query_failed(error: FirestoreError)
signal collection_query_completed(result: FirestoreResult)
signal collection_query_failed(error: FirestoreError)


func _connect_signals() -> void:
	if not _plugin_singleton:
		return
	_plugin_singleton.connect(String(document_written.get_name()), _on_document_written)
	_plugin_singleton.connect(String(document_write_failed.get_name()), _on_document_write_failed)
	_plugin_singleton.connect(String(document_updated.get_name()), _on_document_updated)
	_plugin_singleton.connect(String(document_update_failed.get_name()), _on_document_update_failed)
	_plugin_singleton.connect(String(document_deleted.get_name()), _on_document_deleted)
	_plugin_singleton.connect(String(document_delete_failed.get_name()), _on_document_delete_failed)
	_plugin_singleton.connect(String(document_changed.get_name()), _on_document_changed)
	_plugin_singleton.connect(String(document_query_completed.get_name()), _on_document_query_completed)
	_plugin_singleton.connect(String(document_query_failed.get_name()), _on_document_query_failed)
	_plugin_singleton.connect(String(collection_query_completed.get_name()), _on_collection_query_completed)
	_plugin_singleton.connect(String(collection_query_failed.get_name()), _on_collection_query_failed)


func add_document(document: FirestoreDocument) -> void:
	if _plugin_singleton:
		_plugin_singleton.add_document(document.get_raw_data())


func set_document(document: FirestoreDocument, merge: bool = false) -> void:
	if _plugin_singleton:
		_plugin_singleton.set_document(document.get_raw_data(), merge)


func get_document(collection: String, documentId: String) -> void:
	if _plugin_singleton:
		_plugin_singleton.get_document(collection, documentId)


func get_collection(collection: String) -> void:
	if _plugin_singleton:
		_plugin_singleton.get_collection(collection)


func update_document(document: FirestoreDocument) -> void:
	if _plugin_singleton:
		_plugin_singleton.update_document(document.get_raw_data())


func delete_document(collection: String, documentId: String) -> void:
	if _plugin_singleton:
		_plugin_singleton.delete_document(collection, documentId)


func track_document(collection: String, documentId: String) -> void:
	if _plugin_singleton:
		_plugin_singleton.track_document(collection, documentId)


func stop_tracking_document(collection: String, documentId: String) -> void:
	if _plugin_singleton:
		_plugin_singleton.stop_tracking_document(collection, documentId)


func _on_document_written(document: Dictionary) -> void:
	emit_signal(document_written.get_name(), FirestoreDocument.new(document))


func _on_document_write_failed(error: Dictionary) -> void:
	emit_signal(document_write_failed.get_name(), FirestoreError.new(error))


func _on_document_updated(document: Dictionary) -> void:
	emit_signal(document_updated.get_name(), FirestoreDocument.new(document))


func _on_document_update_failed(error: Dictionary) -> void:
	emit_signal(document_update_failed.get_name(), FirestoreError.new(error))


func _on_document_deleted(document: Dictionary) -> void:
	emit_signal(document_deleted.get_name(), FirestoreDocument.new(document))


func _on_document_delete_failed(error: Dictionary) -> void:
	emit_signal(document_delete_failed.get_name(), FirestoreError.new(error))


func _on_document_changed(document: Dictionary) -> void:
	emit_signal(document_changed.get_name(), FirestoreDocument.new(document))


func _on_document_query_completed(document: Dictionary) -> void:
	emit_signal(document_query_completed.get_name(), FirestoreDocument.new(document))


func _on_document_query_failed(error: Dictionary) -> void:
	emit_signal(document_query_failed.get_name(), FirestoreError.new(error))


func _on_collection_query_completed(result: Dictionary) -> void:
	emit_signal(collection_query_completed.get_name(), FirestoreResult.new(result))


func _on_collection_query_failed(error: Dictionary) -> void:
	emit_signal(collection_query_failed.get_name(), FirestoreError.new(error))
