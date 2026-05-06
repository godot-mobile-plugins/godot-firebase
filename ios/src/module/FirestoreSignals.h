//
// © 2026-present Firebase Team https://github.com/firebase-team
//

#ifndef FirestoreSignals_h
#define FirestoreSignals_h

#include "core/string/ustring.h"

// These constants are defined once here and shared between
// FirebasePluginSignalEmitter.mm and any other translation unit that needs them.
// They must live in a header (not a .mm) so the linker sees a single definition.

static const String SIGNAL_DOCUMENT_WRITTEN = "document_written";
static const String SIGNAL_DOCUMENT_WRITE_FAILED = "document_write_failed";
static const String SIGNAL_DOCUMENT_UPDATED = "document_updated";
static const String SIGNAL_DOCUMENT_UPDATE_FAILED = "document_update_failed";
static const String SIGNAL_DOCUMENT_DELETED = "document_deleted";
static const String SIGNAL_DOCUMENT_DELETE_FAILED = "document_delete_failed";
static const String SIGNAL_DOCUMENT_CHANGED = "document_changed";
static const String SIGNAL_DOCUMENT_QUERY_COMPLETED = "document_query_completed";
static const String SIGNAL_DOCUMENT_QUERY_FAILED = "document_query_failed";
static const String SIGNAL_COLLECTION_QUERY_COMPLETED = "collection_query_completed";
static const String SIGNAL_COLLECTION_QUERY_FAILED = "collection_query_failed";

#endif /* FirestoreSignals_h */
