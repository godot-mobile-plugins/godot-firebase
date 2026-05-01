#
# © 2026-present https://github.com/firebase-team
#

@tool
@icon("../icon.png")
class_name FirebaseAuth extends FirebaseModule

signal auth_success(user: FirebaseUser)
signal auth_failure(error_message: String)
signal link_with_google_success(user: FirebaseUser)
signal link_with_google_failure(error_message: String)
signal sign_out_success(success: bool)
signal password_reset_sent(success: bool)
signal email_verification_sent(success: bool)
signal user_deleted(success: bool)


func _connect_signals() -> void:
	if not _plugin_singleton:
		return
	_plugin_singleton.connect(String(auth_success.get_name()), _on_auth_success)
	_plugin_singleton.connect(String(auth_failure.get_name()), auth_failure.emit)
	_plugin_singleton.connect(String(link_with_google_success.get_name()), _on_link_with_google_success)
	_plugin_singleton.connect(String(link_with_google_failure.get_name()), link_with_google_failure.emit)
	_plugin_singleton.connect(String(sign_out_success.get_name()), sign_out_success.emit)
	_plugin_singleton.connect(String(password_reset_sent.get_name()), password_reset_sent.emit)
	_plugin_singleton.connect(String(email_verification_sent.get_name()), email_verification_sent.emit)
	_plugin_singleton.connect(String(user_deleted.get_name()), user_deleted.emit)


func create_user(email: String, password: String) -> void:
	if _plugin_singleton:
		_plugin_singleton.create_user(email, password)


func link_anonymous_with_google() -> void:
	if _plugin_singleton:
		_plugin_singleton.link_anonymous_with_google()


func sign_in(email: String, password: String) -> void:
	if _plugin_singleton:
		_plugin_singleton.sign_in(email, password)


func sign_in_with_google() -> void:
	if _plugin_singleton:
		_plugin_singleton.sign_in_with_google()


func sign_in_anonymously() -> void:
	if _plugin_singleton:
		_plugin_singleton.sign_in_anonymously()


func is_signed_in() -> bool:
	var status := false
	if _plugin_singleton:
		status = _plugin_singleton.is_signed_in()
	return status


func sign_out() -> void:
	if _plugin_singleton:
		_plugin_singleton.sign_out()


func send_password_reset_email(email: String) -> void:
	if _plugin_singleton:
		_plugin_singleton.send_password_reset_email(email)


func send_verification_email() -> void:
	if _plugin_singleton:
		_plugin_singleton.send_verification_email()


func get_current_user() -> FirebaseUser:
	var __result
	if _plugin_singleton:
		__result = _plugin_singleton.get_current_user()
	return null if __result == null or __result.is_empty() else FirebaseUser.new(__result)


func delete_current_user() -> void:
	if _plugin_singleton:
		_plugin_singleton.delete_current_user()


func _on_auth_success(user_data: Dictionary) -> void:
	auth_success.emit(FirebaseUser.new(user_data))


func _on_link_with_google_success(user_data: Dictionary) -> void:
	link_with_google_success.emit(FirebaseUser.new(user_data))
