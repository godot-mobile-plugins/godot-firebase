#
# © 2026-present https://github.com/<<GitHubUsername>>
#

class_name FirestoreError extends RefCounted

const COLLECTION_PROPERTY := &"collection"
const DOCUMENT_ID_PROPERTY := &"document_id"
const ERROR_PROPERTY := &"error"

var _data: Dictionary


func _init(a_data: Dictionary = {}):
	_data = a_data


func get_collection() -> String:
	return _data[COLLECTION_PROPERTY] if _data.has(COLLECTION_PROPERTY) else ""


func get_document_id() -> String:
	return _data[DOCUMENT_ID_PROPERTY] if _data.has(DOCUMENT_ID_PROPERTY) else ""


func get_error() -> String:
	return _data[ERROR_PROPERTY]
