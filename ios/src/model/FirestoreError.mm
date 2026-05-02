//
// © 2026-present Firebase Team https://github.com/firebase-team
//

#import "FirestoreError.h"

#include "core/object/class_db.h"

static const String GFBCollectionProperty = "collection";
static const String GFBDocumentIdProperty = "document_id";
static const String GFBErrorProperty = "error";

@interface FirestoreError ()
@property(nonatomic, assign) Dictionary data;
@end

@implementation FirestoreError

- (instancetype)initWithCollection:(nullable NSString *)collection
                        documentId:(nullable NSString *)documentId
                             error:(NSString *)error {
    self = [super init];
    if (self) {
        _data = Dictionary();
        self.collection = collection ?: @"";
        self.documentId = documentId ?: @"";
        self.error = error;
    }
    return self;
}

- (instancetype)init {
    return [self initWithCollection:nil documentId:nil error:@""];
}

- (NSString *)collection {
    return self.data.has(GFBCollectionProperty)
            ? [NSString stringWithUTF8String:((String)self.data[GFBCollectionProperty]).utf8().get_data()]
            : @"";
}

- (void)setCollection:(NSString *)collection {
    _data[GFBCollectionProperty] = [collection UTF8String];
}

- (NSString *)documentId {
    return self.data.has(GFBDocumentIdProperty)
            ? [NSString stringWithUTF8String:((String)self.data[GFBDocumentIdProperty]).utf8().get_data()]
            : @"";
}

- (void)setDocumentId:(NSString *)documentId {
    _data[GFBDocumentIdProperty] = [documentId UTF8String];
}

- (NSString *)error {
    return self.data.has(GFBErrorProperty)
            ? [NSString stringWithUTF8String:((String)self.data[GFBErrorProperty]).utf8().get_data()]
            : @"";
}

- (void)setError:(NSString *)error {
    if (error != nil) {
        _data[GFBErrorProperty] = [error UTF8String];
    }
}

- (void *)getRawData {
    return (void *)&_data;
}

@end
