//
// © 2026-present Firebase Team https://github.com/firebase-team
//

#ifndef AuthenticationEmitting_h
#define AuthenticationEmitting_h

#import <Foundation/Foundation.h>

@class GodotFirebaseUser;

/// ObjC protocol that mirrors every signal-emission method on
/// FirebasePluginSignalEmitter.  Authentication.swift depends only on this
/// protocol, so tests can substitute a lightweight mock without needing a live
/// FirebasePlugin Godot object.
NS_ASSUME_NONNULL_BEGIN

@protocol AuthenticationEmitting <NSObject>

- (void)emitAuthSuccess:(GodotFirebaseUser *)user;
- (void)emitAuthFailure:(NSString *)error;
- (void)emitLinkSuccess:(GodotFirebaseUser *)user;
- (void)emitLinkFailure:(NSString *)error;
- (void)emitSignOutSuccess:(BOOL)success;
- (void)emitPasswordResetSent:(BOOL)success;
- (void)emitEmailVerificationSent:(BOOL)success;
- (void)emitUserDeleted:(BOOL)success;

@end

NS_ASSUME_NONNULL_END

#endif /* AuthenticationEmitting_h */
