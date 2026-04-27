//
// © 2026-present https://github.com/firebase-team
//

#ifndef firebase_plugin_h
#define firebase_plugin_h

#import <Foundation/Foundation.h>

#include "core/object/class_db.h"
#include "core/object/object.h"

@class Firebase;
@class FirebasePluginSignalEmitter;
@class Authentication;

class FirebasePlugin : public Object {
	GDCLASS(FirebasePlugin, Object);

private:
	static FirebasePlugin *instance; // Singleton instance
	static FirebasePluginSignalEmitter *signalEmitter; // Signal emitter instance
	static Authentication *authentication; // Authentication handler

	static void _bind_methods();

public:
	void create_user(String email, String password);
	void link_anonymous_with_google();
	void sign_in(String email, String password);
	void sign_in_with_google();
	void sign_in_anonymously();
	bool is_signed_in() const;
	void sign_out();
	void send_verification_email();
	void send_password_reset_email(String email);
	Dictionary get_current_user() const;
	void delete_current_user();

	FirebasePlugin();
	~FirebasePlugin();
};

#endif /* firebase_plugin_h */
