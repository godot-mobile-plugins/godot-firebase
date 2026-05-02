//
// © 2026-present Firebase Team https://github.com/firebase-team
//

#import "FirebasePluginSignalEmitter.h"

// Full model headers — required here because the emit methods call getRawData
// on concrete instances.  SignalEmitting.h only forward-declares these classes,
// which is insufficient for message sends.
#import "FirestoreDocument.h"
#import "FirestoreError.h"
#import "FirestoreResult.h"

#import "firebase_plugin.h"

// Shared Firestore signal name constants (also used by firebase_plugin.mm).
#include "FirestoreSignals.h"

// ---------------------------------------------------------------------------

@interface FirebasePluginSignalEmitter ()
@property(nonatomic, assign) FirebasePlugin *plugin;
@end

// ---------------------------------------------------------------------------

@implementation FirebasePluginSignalEmitter

const String SIGNAL_AUTH_SUCCESS            = "auth_success";
const String SIGNAL_AUTH_FAILURE            = "auth_failure";
const String SIGNAL_LINK_SUCCESS            = "link_with_google_success";
const String SIGNAL_LINK_FAILURE            = "link_with_google_failure";
const String SIGNAL_SIGN_OUT_SUCCESS        = "sign_out_success";
const String SIGNAL_PASSWORD_RESET_SENT     = "password_reset_sent";
const String SIGNAL_EMAIL_VERIFICATION_SENT = "email_verification_sent";
const String SIGNAL_USER_DELETED            = "user_deleted";

static const MethodInfo AUTH_SIGNALS[] = {
	MethodInfo(SIGNAL_AUTH_SUCCESS,            PropertyInfo(Variant::DICTIONARY, "a_user")),
	MethodInfo(SIGNAL_AUTH_FAILURE,            PropertyInfo(Variant::STRING,     "a_error")),
	MethodInfo(SIGNAL_LINK_SUCCESS,            PropertyInfo(Variant::DICTIONARY, "a_user")),
	MethodInfo(SIGNAL_LINK_FAILURE,            PropertyInfo(Variant::STRING,     "a_error")),
	MethodInfo(SIGNAL_SIGN_OUT_SUCCESS,        PropertyInfo(Variant::BOOL,       "a_success")),
	MethodInfo(SIGNAL_PASSWORD_RESET_SENT,     PropertyInfo(Variant::BOOL,       "a_success")),
	MethodInfo(SIGNAL_EMAIL_VERIFICATION_SENT, PropertyInfo(Variant::BOOL,       "a_success")),
	MethodInfo(SIGNAL_USER_DELETED,            PropertyInfo(Variant::BOOL,       "a_success"))
};

static const MethodInfo FIRESTORE_SIGNALS[] = {
	MethodInfo(SIGNAL_DOCUMENT_WRITTEN,           PropertyInfo(Variant::DICTIONARY, "a_document")),
	MethodInfo(SIGNAL_DOCUMENT_WRITE_FAILED,      PropertyInfo(Variant::DICTIONARY, "a_error")),
	MethodInfo(SIGNAL_DOCUMENT_UPDATED,           PropertyInfo(Variant::DICTIONARY, "a_document")),
	MethodInfo(SIGNAL_DOCUMENT_UPDATE_FAILED,     PropertyInfo(Variant::DICTIONARY, "a_error")),
	MethodInfo(SIGNAL_DOCUMENT_DELETED,           PropertyInfo(Variant::DICTIONARY, "a_document")),
	MethodInfo(SIGNAL_DOCUMENT_DELETE_FAILED,     PropertyInfo(Variant::DICTIONARY, "a_error")),
	MethodInfo(SIGNAL_DOCUMENT_CHANGED,           PropertyInfo(Variant::DICTIONARY, "a_document")),
	MethodInfo(SIGNAL_DOCUMENT_QUERY_COMPLETED,   PropertyInfo(Variant::DICTIONARY, "a_document")),
	MethodInfo(SIGNAL_DOCUMENT_QUERY_FAILED,      PropertyInfo(Variant::DICTIONARY, "a_error")),
	MethodInfo(SIGNAL_COLLECTION_QUERY_COMPLETED, PropertyInfo(Variant::DICTIONARY, "a_result")),
	MethodInfo(SIGNAL_COLLECTION_QUERY_FAILED,    PropertyInfo(Variant::DICTIONARY, "a_error"))
};

- (instancetype)initWithPlugin:(void *)plugin {
	self = [super init];
	if (self) {
		_plugin = (FirebasePlugin *)plugin;
	}
	return self;
}

// ---------------------------------------------------------------------------
// Authentication signals
// ---------------------------------------------------------------------------

- (void)emitAuthSuccess:(GodotFirebaseUser *)user {
	self.plugin->emit_signal(SIGNAL_AUTH_SUCCESS, *(Dictionary *)[user getRawData]);
}

- (void)emitAuthFailure:(NSString *)error {
	self.plugin->emit_signal(SIGNAL_AUTH_FAILURE, String([error UTF8String]));
}

- (void)emitLinkSuccess:(GodotFirebaseUser *)user {
	self.plugin->emit_signal(SIGNAL_LINK_SUCCESS, *(Dictionary *)[user getRawData]);
}

- (void)emitLinkFailure:(NSString *)error {
	self.plugin->emit_signal(SIGNAL_LINK_FAILURE, String([error UTF8String]));
}

- (void)emitSignOutSuccess:(BOOL)success {
	self.plugin->emit_signal(SIGNAL_SIGN_OUT_SUCCESS, (bool)success);
}

- (void)emitPasswordResetSent:(BOOL)success {
	self.plugin->emit_signal(SIGNAL_PASSWORD_RESET_SENT, (bool)success);
}

- (void)emitEmailVerificationSent:(BOOL)success {
	self.plugin->emit_signal(SIGNAL_EMAIL_VERIFICATION_SENT, (bool)success);
}

- (void)emitUserDeleted:(BOOL)success {
	self.plugin->emit_signal(SIGNAL_USER_DELETED, (bool)success);
}

+ (const MethodInfo *)getAuthSignals {
	return AUTH_SIGNALS;
}

+ (int)getAuthSignalsCount {
	return sizeof(AUTH_SIGNALS) / sizeof(MethodInfo);
}

// ---------------------------------------------------------------------------
// Firestore signals
// ---------------------------------------------------------------------------

- (void)emitDocumentWritten:(FirestoreDocument *)document {
	self.plugin->emit_signal(SIGNAL_DOCUMENT_WRITTEN, *(Dictionary *)[document getRawData]);
}

- (void)emitDocumentWriteFailed:(FirestoreError *)error {
	self.plugin->emit_signal(SIGNAL_DOCUMENT_WRITE_FAILED, *(Dictionary *)[error getRawData]);
}

- (void)emitDocumentUpdated:(FirestoreDocument *)document {
	self.plugin->emit_signal(SIGNAL_DOCUMENT_UPDATED, *(Dictionary *)[document getRawData]);
}

- (void)emitDocumentUpdateFailed:(FirestoreError *)error {
	self.plugin->emit_signal(SIGNAL_DOCUMENT_UPDATE_FAILED, *(Dictionary *)[error getRawData]);
}

- (void)emitDocumentDeleted:(FirestoreDocument *)document {
	self.plugin->emit_signal(SIGNAL_DOCUMENT_DELETED, *(Dictionary *)[document getRawData]);
}

- (void)emitDocumentDeleteFailed:(FirestoreError *)error {
	self.plugin->emit_signal(SIGNAL_DOCUMENT_DELETE_FAILED, *(Dictionary *)[error getRawData]);
}

- (void)emitDocumentChanged:(FirestoreDocument *)document {
	self.plugin->emit_signal(SIGNAL_DOCUMENT_CHANGED, *(Dictionary *)[document getRawData]);
}

- (void)emitDocumentQueryCompleted:(FirestoreDocument *)document {
	self.plugin->emit_signal(SIGNAL_DOCUMENT_QUERY_COMPLETED, *(Dictionary *)[document getRawData]);
}

- (void)emitDocumentQueryFailed:(FirestoreError *)error {
	self.plugin->emit_signal(SIGNAL_DOCUMENT_QUERY_FAILED, *(Dictionary *)[error getRawData]);
}

- (void)emitCollectionQueryCompleted:(FirestoreResult *)result {
	self.plugin->emit_signal(SIGNAL_COLLECTION_QUERY_COMPLETED, *(Dictionary *)[result getRawData]);
}

- (void)emitCollectionQueryFailed:(FirestoreError *)error {
	self.plugin->emit_signal(SIGNAL_COLLECTION_QUERY_FAILED, *(Dictionary *)[error getRawData]);
}

+ (const MethodInfo *)getFirestoreSignals {
	return FIRESTORE_SIGNALS;
}

+ (int)getFirestoreSignalsCount {
	return sizeof(FIRESTORE_SIGNALS) / sizeof(MethodInfo);
}

@end
