#
# © 2026-present https://github.com/<<GitHubUsername>>
#

class_name FirestoreDocument extends RefCounted

const COLLECTION_PROPERTY := &"collection"
const DOCUMENT_ID_PROPERTY := &"document_id"
const DOCUMENT_DATA_PROPERTY := &"document_data"

var _data: Dictionary


func _init(a_data: Dictionary = {}):
	_data = a_data


func get_collection() -> String:
	return _data[COLLECTION_PROPERTY] if _data.has(COLLECTION_PROPERTY) else ""


func set_collection(a_collection: String) -> FirestoreDocument:
	_data[COLLECTION_PROPERTY] = a_collection
	return self


func get_document_id() -> String:
	return _data[DOCUMENT_ID_PROPERTY]


func set_document_id(a_document_id: String) -> FirestoreDocument:
	_data[DOCUMENT_ID_PROPERTY] = a_document_id
	return self


func get_all_values() -> Dictionary:
	return _data[DOCUMENT_DATA_PROPERTY]


func set_all_values(a_document_data: Dictionary) -> FirestoreDocument:
	_data[DOCUMENT_DATA_PROPERTY] = a_document_data
	return self


func get_value(a_key):
	return _data[DOCUMENT_DATA_PROPERTY][a_key] if _data[DOCUMENT_DATA_PROPERTY].has(a_key) else null


func set_value(a_key, a_value) -> FirestoreDocument:
	if not _data[DOCUMENT_DATA_PROPERTY]:
		_data[DOCUMENT_DATA_PROPERTY] = {}
	_data[DOCUMENT_DATA_PROPERTY][a_key] = a_value
	return self


func get_raw_data() -> Dictionary:
	return _data
