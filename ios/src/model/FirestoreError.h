//
// © 2026-present Firebase Team https://github.com/firebase-team
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FirestoreError : NSObject

- (instancetype)initWithCollection:(nullable NSString *)collection
                        documentId:(nullable NSString *)documentId
                             error:(NSString *)error NS_DESIGNATED_INITIALIZER;

- (instancetype)init;

@property(nonatomic, copy) NSString *collection;
@property(nonatomic, copy) NSString *documentId;
@property(nonatomic, copy) NSString *error;

- (void *)getRawData;

@end

NS_ASSUME_NONNULL_END
