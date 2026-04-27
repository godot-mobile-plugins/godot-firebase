
//
// © 2026-present Firebase Team https://github.com/firebase-team
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GodotFirebaseUser : NSObject

/// Designated initialiser — builds the model from raw field values.
- (instancetype)initWithUserId:(NSString *)userId
						  name:(nullable NSString *)name
						 email:(nullable NSString *)email
					  photoUrl:(nullable NSString *)photoUrl
			   isEmailVerified:(BOOL)isEmailVerified
				   isAnonymous:(BOOL)isAnonymous NS_DESIGNATED_INITIALIZER;

- (instancetype)init;

@property(nonatomic, copy) NSString *userId;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *email;
@property(nonatomic, copy) NSString *photoUrl;
@property(nonatomic, assign) BOOL isEmailVerified;
@property(nonatomic, assign) BOOL isAnonymous;

/// Returns the backing Dictionary
- (void *)getRawData;

@end

NS_ASSUME_NONNULL_END
