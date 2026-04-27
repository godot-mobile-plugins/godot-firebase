#
# © 2026-present https://github.com/<<GitHubUsername>>
#

class_name FirebaseUser extends RefCounted

const USER_ID_PROPERTY := &"user_id"
const NAME_PROPERTY := &"name"
const EMAIL_PROPERTY := &"email"
const PHOTO_URL_PROPERTY := &"photo_url"
const IS_EMAIL_VERIFIED_PROPERTY := &"is_email_verified"
const IS_ANONYMOUS_PROPERTY := &"is_anonymous"

var _data: Dictionary


func _init(a_data: Dictionary = {}):
	_data = a_data


func get_user_id() -> String:
	return _data[USER_ID_PROPERTY]


func set_user_id(a_user_id: String) -> void:
	_data[USER_ID_PROPERTY] = a_user_id


func get_name() -> String:
	return _data[NAME_PROPERTY]


func set_name(a_name: String) -> void:
	_data[NAME_PROPERTY] = a_name


func get_email() -> String:
	return _data[EMAIL_PROPERTY]


func set_email(a_email: String) -> void:
	_data[EMAIL_PROPERTY] = a_email


func get_photo_url() -> String:
	return _data[PHOTO_URL_PROPERTY]


func set_photo_url(a_photo_url: String) -> void:
	_data[PHOTO_URL_PROPERTY] = a_photo_url


func get_is_email_verified() -> bool:
	return _data[IS_EMAIL_VERIFIED_PROPERTY]


func set_is_email_verified(a_is_email_verified: bool) -> void:
	_data[IS_EMAIL_VERIFIED_PROPERTY] = a_is_email_verified


func get_is_anonymous() -> bool:
	return _data[IS_ANONYMOUS_PROPERTY]


func set_is_anonymous(a_is_anonymous: bool) -> void:
	_data[IS_ANONYMOUS_PROPERTY] = a_is_anonymous
