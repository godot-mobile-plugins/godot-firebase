//
// © 2026-present Firebase Team https://github.com/firebase-team
//

#import "GodotFirebaseUser.h"

#include "core/object/class_db.h"

// ---------------------------------------------------------------------------
// Data key constants
// ---------------------------------------------------------------------------

static const String GFBUserIdProperty = "user_id";
static const String GFBNameProperty = "name";
static const String GFBEmailProperty = "email";
static const String GFBPhotoUrlProperty = "photo_url";
static const String GFBIsEmailVerifiedProperty = "is_email_verified";
static const String GFBIsAnonymousProperty = "is_anonymous";

// ---------------------------------------------------------------------------

@interface GodotFirebaseUser ()
@property(nonatomic, assign) Dictionary data;
@end

@implementation GodotFirebaseUser

// ---------------------------------------------------------------------------
// Initialisers
// ---------------------------------------------------------------------------

- (instancetype)initWithUserId:(NSString *)userId
						  name:(nullable NSString *)name
						 email:(nullable NSString *)email
					  photoUrl:(nullable NSString *)photoUrl
			   isEmailVerified:(BOOL)isEmailVerified
				   isAnonymous:(BOOL)isAnonymous {
	self = [super init];
	if (self) {
		_data = Dictionary();
		// Use the public setters so property observers remain consistent.
		self.userId = userId;
		self.name = name ?: @"";
		self.email = email ?: @"";
		self.photoUrl = photoUrl ?: @"";
		self.isEmailVerified = isEmailVerified;
		self.isAnonymous = isAnonymous;
	}
	return self;
}

- (instancetype)init {
	return [self initWithUserId:@"" name:nil email:nil photoUrl:nil isEmailVerified:NO isAnonymous:NO];
}

// ---------------------------------------------------------------------------
// Property accessors — read/write through the backing dictionary so that
// getRawData() always reflects the latest values, mirroring how the Kotlin
// class stores everything inside a single Dictionary object.
// ---------------------------------------------------------------------------

- (NSString *)userId {
	return self.data.has(GFBUserIdProperty)
			? [NSString stringWithUTF8String:((String)self.data[GFBUserIdProperty]).utf8().get_data()]
			: @"";
}

- (void)setUserId:(NSString *)userId {
	if (userId != nil) {
		_data[GFBUserIdProperty] = [userId UTF8String];
	}
}

- (NSString *)name {
	return self.data.has(GFBNameProperty)
			? [NSString stringWithUTF8String:((String)self.data[GFBNameProperty]).utf8().get_data()]
			: @"";
}

- (void)setName:(NSString *)name {
	if (name != nil) {
		_data[GFBNameProperty] = [name UTF8String];
	}
}

- (NSString *)email {
	return self.data.has(GFBEmailProperty)
			? [NSString stringWithUTF8String:((String)self.data[GFBEmailProperty]).utf8().get_data()]
			: @"";
}

- (void)setEmail:(NSString *)email {
	if (email != nil) {
		_data[GFBEmailProperty] = [email UTF8String];
	}
}

- (NSString *)photoUrl {
	return self.data.has(GFBPhotoUrlProperty)
			? [NSString stringWithUTF8String:((String)self.data[GFBPhotoUrlProperty]).utf8().get_data()]
			: @"";
}

- (void)setPhotoUrl:(NSString *)photoUrl {
	if (photoUrl != nil) {
		_data[GFBPhotoUrlProperty] = [photoUrl UTF8String];
	}
}

- (BOOL)isEmailVerified {
	return self.data.has(GFBIsEmailVerifiedProperty) ? (BOOL)self.data[GFBIsEmailVerifiedProperty] : NO;
}

- (void)setIsEmailVerified:(BOOL)isEmailVerified {
	_data[GFBIsEmailVerifiedProperty] = isEmailVerified;
}

- (BOOL)isAnonymous {
	return self.data.has(GFBIsAnonymousProperty) ? (BOOL)self.data[GFBIsAnonymousProperty] : NO;
}

- (void)setIsAnonymous:(BOOL)isAnonymous {
	_data[GFBIsAnonymousProperty] = isAnonymous;
}

- (void *)getRawData {
	return (void *)&_data;
}

@end
