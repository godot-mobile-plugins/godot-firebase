#
# © 2026-present https://github.com/firebase-team
#

extends Node

@onready var firebase_node: Firebase = $Firebase
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

# Firestore
@onready var collection_le: LineEdit = %CollectionLE
@onready var document_id_le: LineEdit = %DocumentIdLE
@onready var add_document_button: Button = %AddDocumentButton
@onready var set_document_button: Button = %SetDocumentButton
@onready var get_document_button: Button = %GetDocumentButton
@onready var get_documents_button: Button = %GetDocumentsButton
@onready var update_document_button: Button = %UpdateDocumentButton
@onready var delete_document_button: Button = %DeleteDocumentButton
@onready var track_document_button: Button = %TrackDocumentButton
@onready var stop_tracking_button: Button = %StopTrackingButton


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

# Authentication

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
			"Current user: [id= %s, email= %s]" % [__user.get_user_id(), __user.get_email()]
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
	_print_to_screen("Sending verification email for current user")
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


func _on_firebase_auth_auth_failure(error_message: String) -> void:
	_print_to_screen("Firebase authentication failed: %s" % error_message)


func _on_firebase_auth_auth_success(user: FirebaseUser) -> void:
	_print_to_screen("%s signed in successfully to Firebase" % user.get_email())


func _on_firebase_auth_email_verification_sent(success: bool) -> void:
	_print_to_screen("Verification email dispatch %s" % ("succeeded" if success else "failed"))


func _on_firebase_auth_link_with_google_failure(error_message: String) -> void:
	_print_to_screen("Failed to link with Google: %s" % error_message)


func _on_firebase_auth_link_with_google_success(user: FirebaseUser) -> void:
	_print_to_screen("Linked %s with Google successfully" % user.get_email())


func _on_firebase_auth_password_reset_sent(success: bool) -> void:
	_print_to_screen("Password reset email dispatch " % ("succeeded" if success else "failed"))


func _on_firebase_auth_sign_out_success(success: bool) -> void:
	_print_to_screen("Signout %s" % ("succeeded" if success else "failed"))


func _on_firebase_auth_user_deleted(success: bool) -> void:
	_print_to_screen("User deletion %s" % ("succeeded" if success else "failed"))


# Firestore

func _on_add_document_button_pressed() -> void:
	_print_to_screen("Adding document %s/%s" % [collection_le.text, document_id_le.text])
	var __doc := FirestoreDocument.new().set_collection(collection_le.text)
	__doc.set_all_values({ "my": "important", "data": 1})
	firebase_node.firestore.add_document(__doc)


func _on_set_document_button_pressed() -> void:
	_print_to_screen("Setting document %s/%s" % [collection_le.text, document_id_le.text])
	var __doc := FirestoreDocument.new().set_collection(collection_le.text)
	__doc.set_document_id(document_id_le.text)
	__doc.set_all_values({ "another": "important", "data": 2})
	firebase_node.firestore.set_document(__doc)


func _on_get_document_button_pressed() -> void:
	_print_to_screen("Requesting document %s/%s" % [collection_le.text, document_id_le.text])
	firebase_node.firestore.get_document(collection_le.text, document_id_le.text)


func _on_get_documents_button_pressed() -> void:
	_print_to_screen("Requesting documents in collection %s" % [collection_le.text])
	firebase_node.firestore.get_collection(collection_le.text)


func _on_update_document_button_pressed() -> void:
	_print_to_screen("Updating document %s/%s" % [collection_le.text, document_id_le.text])
	var __doc := FirestoreDocument.new().set_collection(collection_le.text)
	__doc.set_document_id(document_id_le.text)
	__doc.set_all_values({ "another": "updated", "data": 3})
	firebase_node.firestore.update_document(__doc)


func _on_delete_document_button_pressed() -> void:
	_print_to_screen("Deleting document %s/%s" % [collection_le.text, document_id_le.text])
	firebase_node.firestore.delete_document(collection_le.text, document_id_le.text)


func _on_track_document_button_pressed() -> void:
	_print_to_screen("Requesting to track document %s/%s" % [collection_le.text, document_id_le.text])
	firebase_node.firestore.track_document(collection_le.text, document_id_le.text)


func _on_stop_tracking_button_pressed() -> void:
	_print_to_screen("Requesting to stop tracking document %s/%s" % [collection_le.text, document_id_le.text])
	firebase_node.firestore.stop_tracking_document(collection_le.text, document_id_le.text)


func _on_firestore_document_changed(document: FirestoreDocument) -> void:
	_print_to_screen("Firestore document %s/%s changed"
			% [document.get_collection(), document.get_document_id()])


func _on_firestore_document_delete_failed(error: FirestoreError) -> void:
	_print_to_screen("Firestore document %s/%s deletion failed:"
			% [error.get_collection(), error.get_document_id()])


func _on_firestore_document_deleted(result: FirestoreDocument) -> void:
	_print_to_screen("Firestore document %s/%s deleted"
			% [result.get_collection(), result.get_document_id()])


func _on_firestore_document_update_failed(error: FirestoreError) -> void:
	_print_to_screen("Firestore document %s/%s update failed:"
			% [error.get_collection(), error.get_document_id()])


func _on_firestore_document_updated(result: FirestoreDocument) -> void:
	_print_to_screen("Firestore document %s/%s updated successfully"
			% [result.get_collection(), result.get_document_id()])


func _on_firestore_document_write_failed(error: FirestoreError) -> void:
	_print_to_screen("Firestore write %s/%s deletion failed:"
			% [error.get_collection(), error.get_document_id()])


func _on_firestore_document_written(result: FirestoreDocument) -> void:
	_print_to_screen("Firestore document %s/%s written successfully"
			% [result.get_collection(), result.get_document_id()])


func _on_firestore_document_query_completed(document: FirestoreDocument) -> void:
	var __document_data := document.get_all_values()
	_print_to_screen("Firestore document query returned %s/%s with %d values"
				% [document.get_collection(), document.get_document_id(), __document_data.size()])


func _on_firestore_document_query_failed(error: FirestoreError) -> void:
	_print_to_screen("Firestore document query for %s/%s failed:"
			% [error.get_collection(), error.get_document_id()])


func _on_firestore_collection_query_completed(result: FirestoreResult) -> void:
	var __documents_ids = result.get_all_document_ids()
	_print_to_screen("Firestore document query for %s returned %d results"
			% [result.get_collection(), __documents_ids.size()])
	for __document_id in __documents_ids:
		var __document = result.get_document(__document_id)
		_print_to_screen("Retrieved document: %s/%s"
				% [__document.get_collection(), __document_id])

func _on_firestore_collection_query_failed(error: FirestoreError) -> void:
	_print_to_screen("Firestore collection query for %s failed:"
			% [error.get_collection()])
