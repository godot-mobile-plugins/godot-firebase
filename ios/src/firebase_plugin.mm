//
// © 2026-present https://github.com/firebase-team
//

#import "firebase_plugin.h"

#import "FirebasePluginSignalEmitter.h"
#import "app_delegate_service.h"
#import "firebase_logger.h"
#import "firebase_plugin-Swift.h"
#import "godot_view_controller.h"

@interface FirebasePluginSignalEmitter ()
+ (const MethodInfo *)getAuthSignals;
+ (int)getAuthSignalsCount;
@end

FirebasePlugin *FirebasePlugin::instance = NULL;

void FirebasePlugin::_bind_methods() {
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

	const MethodInfo *signals = [FirebasePluginSignalEmitter getAuthSignals];
	int signal_count = [FirebasePluginSignalEmitter getAuthSignalsCount];
	for (int i = 0; i < signal_count; i++) {
		ADD_SIGNAL(signals[i]);
	}
}

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

FirebasePlugin::FirebasePlugin() {
	os_log_debug(firebase_log, "Plugin singleton constructor");

	ERR_FAIL_COND(instance != NULL);

	instance = this;
	signalEmitter = [[FirebasePluginSignalEmitter alloc] initWithPlugin:this];
	authentication = [[Authentication alloc] initWithEmitter:signalEmitter
											  viewController:GDTAppDelegateService.viewController];
}

FirebasePlugin::~FirebasePlugin() {
	os_log_debug(firebase_log, "Plugin singleton destructor");

	if (instance == this) {
		instance = nullptr;
	}
}
