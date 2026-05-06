//
// © 2026-present Firebase Team https://github.com/firebase-team
//

#ifndef SignalEmitting_h
#define SignalEmitting_h

#import <Foundation/Foundation.h>

@class GodotFirebaseUser;
@class FirestoreDocument;
@class FirestoreError;
@class FirestoreResult;

/// ObjC protocol that mirrors every signal-emission method on
/// FirebasePluginSignalEmitter.  Authentication.swift and Firestore.swift
/// depend only on this protocol, so tests can substitute lightweight mocks
/// without needing a live FirebasePlugin Godot object.
NS_ASSUME_NONNULL_BEGIN

@protocol SignalEmitting <NSObject>

// Authentication signals
- (void)emitAuthSuccess:(GodotFirebaseUser *)user;
- (void)emitAuthFailure:(NSString *)error;
- (void)emitLinkSuccess:(GodotFirebaseUser *)user;
- (void)emitLinkFailure:(NSString *)error;
- (void)emitSignOutSuccess:(BOOL)success;
- (void)emitPasswordResetSent:(BOOL)success;
- (void)emitEmailVerificationSent:(BOOL)success;
- (void)emitUserDeleted:(BOOL)success;

// Firestore signals
- (void)emitDocumentWritten:(FirestoreDocument *)document;
- (void)emitDocumentWriteFailed:(FirestoreError *)error;
- (void)emitDocumentUpdated:(FirestoreDocument *)document;
- (void)emitDocumentUpdateFailed:(FirestoreError *)error;
- (void)emitDocumentDeleted:(FirestoreDocument *)document;
- (void)emitDocumentDeleteFailed:(FirestoreError *)error;
- (void)emitDocumentChanged:(FirestoreDocument *)result;
- (void)emitDocumentQueryCompleted:(FirestoreDocument *)result;
- (void)emitDocumentQueryFailed:(FirestoreError *)error;
- (void)emitCollectionQueryCompleted:(FirestoreResult *)result;
- (void)emitCollectionQueryFailed:(FirestoreError *)error;

@end

NS_ASSUME_NONNULL_END

#endif /* SignalEmitting_h */
