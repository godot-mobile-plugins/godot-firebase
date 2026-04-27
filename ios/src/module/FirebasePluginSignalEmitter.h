//
// © 2026-present Firebase Team https://github.com/firebase-team
//

#import <Foundation/Foundation.h>

#import "AuthenticationEmitting.h"
#import "GodotFirebaseUser.h"

NS_ASSUME_NONNULL_BEGIN

/// Concrete signal emitter that forwards every Firebase auth event to the
/// Godot engine via FirebasePlugin::emit_signal.
/// Conforms to AuthenticationEmitting so Authentication.swift can hold only
/// a protocol reference, enabling mock substitution in unit tests.
///
/// NOTE: getAuthSignals / getAuthSignalsCount return the Godot C++ MethodInfo
/// type and are therefore declared only as a private class extension inside
/// FirebasePluginSignalEmitter.mm, which is compiled as Objective-C++.
/// They must never appear here because this header is pulled into the Swift
/// bridging header, where C++ types are not available.
@interface FirebasePluginSignalEmitter : NSObject <AuthenticationEmitting>

- (instancetype)initWithPlugin:(void *)plugin;

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
