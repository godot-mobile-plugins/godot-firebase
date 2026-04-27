#
# © 2026-present https://github.com/firebase-team
#

extends Node

@onready var firebase_node: Firebase = $Firebase
@onready var get_firebase_button: Button = $CanvasLayer/MainContainer/VBoxContainer/GetStateButton
@onready var _label: RichTextLabel = $CanvasLayer/MainContainer/VBoxContainer/RichTextLabel as RichTextLabel
@onready var _android_texture_rect := %AndroidTextureRect as TextureRect
@onready var _ios_texture_rect := %iOSTextureRect as TextureRect

# Authentication
@onready var email_le: LineEdit = %EmailLE
@onready var password_le: LineEdit = %PasswordLE
@onready var create_user_button: Button = %CreateUserButton
@onready var sign_in_button: Button = %SignInButton
@onready var anon_sign_in_button: Button = %AnonSignInButton
@onready var is_signed_in_button: Button = %IsSignedInButton
@onready var get_user_button: Button = %GetUserButton
@onready var sign_out_button: Button = %SignOutButton
@onready var delete_user_button: Button = %DeleteUserButton

var _active_texture_rect: TextureRect


func _ready() -> void:
	if OS.has_feature("ios"):
		_android_texture_rect.hide()
		_active_texture_rect = _ios_texture_rect
	else:
		_ios_texture_rect.hide()
		_active_texture_rect = _android_texture_rect


func _print_to_screen(a_message: String, a_is_error: bool = false) -> void:
	if a_is_error:
		_label.push_color(Color.CRIMSON)

	_label.add_text("%s\n\n" % a_message)

	if a_is_error:
		_label.pop()
		printerr("Demo app:: " + a_message)
	else:
		print("Demo app:: " + a_message)

	_label.scroll_to_line(_label.get_line_count() - 1)


func _on_create_user_button_pressed() -> void:
	_print_to_screen("Creating user with email %s" % email_le.text)
	firebase_node.auth.create_user(email_le.text, password_le.text)


func _on_sign_in_button_pressed() -> void:
	_print_to_screen("Signing in with email %s" % email_le.text)
	firebase_node.auth.sign_in(email_le.text, password_le.text)


func _on_anon_sign_in_button_pressed() -> void:
	_print_to_screen("Signing in anonymously")
	firebase_node.auth.sign_in_anonymously()


func _on_is_signed_in_button_pressed() -> void:
	if firebase_node.auth.is_signed_in():
		_print_to_screen("A user is signed in")
	else:
		_print_to_screen("No users signed in")


func _on_get_user_button_pressed() -> void:
	var __user := firebase_node.auth.get_current_user()
	if __user:
		_print_to_screen(
			"Current user: [id= %s, name= %s, email= %s]" % [__user.get_user_id, __user.get_name(), __user.get_email()]
		)
	else:
		_print_to_screen("No user is signed in")


func _on_sign_out_button_pressed() -> void:
	_print_to_screen("Signing out current user")
	firebase_node.auth.sign_out()


func _on_delete_user_button_pressed() -> void:
	_print_to_screen("Deleting current user")
	firebase_node.auth.delete_current_user()


func _on_verify_email_button_pressed() -> void:
	_print_to_screen("Sending reset email for current user")
	firebase_node.auth.send_verification_email()


func _on_reset_email_button_pressed() -> void:
	_print_to_screen("Sending reset email for %s" % email_le.text)
	firebase_node.auth.send_password_reset_email(email_le.text)


func _on_link_google_button_pressed() -> void:
	_print_to_screen("Linking with Google")
	firebase_node.auth.link_anonymous_with_google()


func _on_sign_in_google_button_pressed() -> void:
	_print_to_screen("Signing in with Google")
	firebase_node.auth.sign_in_with_google()
