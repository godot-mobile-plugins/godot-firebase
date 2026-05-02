//
// © 2026-present https://github.com/firebase-team
//

#import "firebase_plugin.h"

// Import full model headers BEFORE FirebasePluginSignalEmitter.h.
// FirebasePluginSignalEmitter.h -> SignalEmitting.h only @class-forward-declares
// FirestoreDocument, FirestoreError, and FirestoreResult. The full @interface
// must be visible before any forward declaration can shadow it, otherwise the
// class extension and alloc/initWithDictionary: calls below fail to resolve.
#import "FirestoreDocument.h"
#import "FirestoreError.h"
#import "FirestoreResult.h"

#import "FirebasePluginSignalEmitter.h"
#import "app_delegate_service.h"
#import "firebase_logger.h"
#import "firebase_plugin-Swift.h"
#import "godot_view_controller.h"

#include "FirestoreSignals.h"

// ---------------------------------------------------------------------------

@interface FirebasePluginSignalEmitter ()
+ (const MethodInfo *)getAuthSignals;
+ (int)getAuthSignalsCount;
+ (const MethodInfo *)getFirestoreSignals;
+ (int)getFirestoreSignalsCount;
@end

// ---------------------------------------------------------------------------
// Expose the package-private initWithDictionary: convenience initialiser so
// the C++ Firestore methods can construct model objects directly from a Godot
// Dictionary without going through the public designated initialiser.
@interface FirestoreDocument ()
- (instancetype)initWithDictionary:(Dictionary)dictionary;
@end

// ---------------------------------------------------------------------------

FirebasePlugin *FirebasePlugin::instance = NULL;

void FirebasePlugin::_bind_methods() {
	// Authentication methods
	ClassDB::bind_method(D_METHOD("create_user"), &FirebasePlugin::create_user);
	ClassDB::bind_method(D_METHOD("link_anonymous_with_google"), &FirebasePlugin::link_anonymous_with_google);
	ClassDB::bind_method(D_METHOD("sign_in"), &FirebasePlugin::sign_in);
	ClassDB::bind_method(D_METHOD("sign_in_with_google"), &FirebasePlugin::sign_in_with_google);
	ClassDB::bind_method(D_METHOD("sign_in_anonymously"), &FirebasePlugin::sign_in_anonymously);
	ClassDB::bind_method(D_METHOD("is_signed_in"), &FirebasePlugin::is_signed_in);
	ClassDB::bind_method(D_METHOD("sign_out"), &FirebasePlugin::sign_out);
	ClassDB::bind_method(D_METHOD("send_verification_email"), &FirebasePlugin::send_verification_email);
	ClassDB::bind_method(D_METHOD("send_password_reset_email"), &FirebasePlugin::send_password_reset_email);
	ClassDB::bind_method(D_METHOD("get_current_user"), &FirebasePlugin::get_current_user);
	ClassDB::bind_method(D_METHOD("delete_current_user"), &FirebasePlugin::delete_current_user);

	// Firestore methods
	ClassDB::bind_method(D_METHOD("add_document"), &FirebasePlugin::add_document);
	ClassDB::bind_method(D_METHOD("set_document", "document", "merge"), &FirebasePlugin::set_document, DEFVAL(false));
	ClassDB::bind_method(D_METHOD("get_document"), &FirebasePlugin::get_document);
	ClassDB::bind_method(D_METHOD("update_document"), &FirebasePlugin::update_document);
	ClassDB::bind_method(D_METHOD("delete_document"), &FirebasePlugin::delete_document);
	ClassDB::bind_method(D_METHOD("get_collection"), &FirebasePlugin::get_collection);
	ClassDB::bind_method(D_METHOD("track_document"), &FirebasePlugin::track_document);
	ClassDB::bind_method(D_METHOD("stop_tracking_document"), &FirebasePlugin::stop_tracking_document);

	// Authentication signals
	const MethodInfo *authSignals = [FirebasePluginSignalEmitter getAuthSignals];
	int authSignalCount = [FirebasePluginSignalEmitter getAuthSignalsCount];
	for (int i = 0; i < authSignalCount; i++) {
		ADD_SIGNAL(authSignals[i]);
	}

	// Firestore signals
	const MethodInfo *firestoreSignals = [FirebasePluginSignalEmitter getFirestoreSignals];
	int firestoreSignalCount = [FirebasePluginSignalEmitter getFirestoreSignalsCount];
	for (int i = 0; i < firestoreSignalCount; i++) {
		ADD_SIGNAL(firestoreSignals[i]);
	}
}

// ---------------------------------------------------------------------------
// Authentication methods
// ---------------------------------------------------------------------------

void FirebasePlugin::create_user(String email, String password) {
	[authentication createUser:[NSString stringWithUTF8String:(email).utf8().get_data()]
					  password:[NSString stringWithUTF8String:(password).utf8().get_data()]];
}

void FirebasePlugin::link_anonymous_with_google() {
	[authentication linkAnonymousWithGoogle];
}

void FirebasePlugin::sign_in(String email, String password) {
	[authentication signIn:[NSString stringWithUTF8String:(email).utf8().get_data()]
				  password:[NSString stringWithUTF8String:(password).utf8().get_data()]];
}

void FirebasePlugin::sign_in_with_google() {
	[authentication signInWithGoogle];
}

void FirebasePlugin::sign_in_anonymously() {
	[authentication signInAnonymously];
}

bool FirebasePlugin::is_signed_in() const {
	return [authentication isSignedIn];
}

void FirebasePlugin::sign_out() {
	[authentication signOut];
}

void FirebasePlugin::send_verification_email() {
	[authentication sendVerificationEmail];
}

void FirebasePlugin::send_password_reset_email(String email) {
	[authentication sendPasswordResetEmail:[NSString stringWithUTF8String:(email).utf8().get_data()]];
}

Dictionary FirebasePlugin::get_current_user() const {
	GodotFirebaseUser *user = [authentication getCurrentUser];
	if (user) {
		return *(Dictionary *)[user getRawData];
	}
	return Dictionary();
}

void FirebasePlugin::delete_current_user() {
	[authentication deleteCurrentUser];
}

// ---------------------------------------------------------------------------
// Firestore methods
// ---------------------------------------------------------------------------

void FirebasePlugin::add_document(Dictionary document) {
	[firestore addDocument:[[FirestoreDocument alloc] initWithDictionary:document]];
}

void FirebasePlugin::set_document(Dictionary document, bool merge) {
	[firestore setDocument:[[FirestoreDocument alloc] initWithDictionary:document] merge:merge];
}

void FirebasePlugin::get_document(String collection, String documentId) {
	[firestore getDocument:[NSString stringWithUTF8String:(collection).utf8().get_data()]
			   documentId:[NSString stringWithUTF8String:(documentId).utf8().get_data()]];
}

void FirebasePlugin::update_document(Dictionary document) {
	[firestore updateDocument:[[FirestoreDocument alloc] initWithDictionary:document]];
}

void FirebasePlugin::delete_document(String collection, String documentId) {
	[firestore deleteDocument:[NSString stringWithUTF8String:(collection).utf8().get_data()]
				  documentId:[NSString stringWithUTF8String:(documentId).utf8().get_data()]];
}

void FirebasePlugin::get_collection(String collection) {
	[firestore getCollection:[NSString stringWithUTF8String:(collection).utf8().get_data()]];
}

void FirebasePlugin::track_document(String collection, String documentId) {
	[firestore trackDocument:[NSString stringWithUTF8String:(collection).utf8().get_data()]
				 documentId:[NSString stringWithUTF8String:(documentId).utf8().get_data()]];
}

void FirebasePlugin::stop_tracking_document(String collection, String documentId) {
	[firestore stopTrackingDocument:[NSString stringWithUTF8String:(collection).utf8().get_data()]
					    documentId:[NSString stringWithUTF8String:(documentId).utf8().get_data()]];
}

// ---------------------------------------------------------------------------
// Lifecycle
// ---------------------------------------------------------------------------

FirebasePlugin::FirebasePlugin() {
	os_log_debug(firebase_log, "Plugin singleton constructor");

	ERR_FAIL_COND(instance != NULL);

	instance = this;
	signalEmitter = [[FirebasePluginSignalEmitter alloc] initWithPlugin:this];
	authentication = [[Authentication alloc] initWithEmitter:signalEmitter
											  viewController:GDTAppDelegateService.viewController];
	firestore = [[Firestore alloc] initWithEmitter:signalEmitter];
}

FirebasePlugin::~FirebasePlugin() {
	os_log_debug(firebase_log, "Plugin singleton destructor");

	if (instance == this) {
		instance = nullptr;
	}
}
