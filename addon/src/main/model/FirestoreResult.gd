#
# © 2026-present https://github.com/<<GitHubUsername>>
#

class_name FirestoreResult extends RefCounted

const COLLECTION_PROPERTY := &"collection"
const DOCUMENTS_PROPERTY := &"documents"

var _data: Dictionary


func _init(a_data: Dictionary = {}):
	_data = a_data


func get_collection() -> String:
	return _data[COLLECTION_PROPERTY] if _data.has(COLLECTION_PROPERTY) else ""


func get_document(a_document_id: String) -> FirestoreDocument:
	if not _data.has(DOCUMENTS_PROPERTY):
		return null
	return (
		FirestoreDocument.new(_data[DOCUMENTS_PROPERTY][a_document_id])
		if _data[DOCUMENTS_PROPERTY].has(a_document_id)
		else null
	)


func get_all_document_ids() -> Array:
	var __documents_dictionary: Dictionary
	if _data.has(DOCUMENTS_PROPERTY):
		__documents_dictionary = _data[DOCUMENTS_PROPERTY] as Dictionary

	return __documents_dictionary.keys() if __documents_dictionary else []
