//
//  LookinArchiveDocument.h
//  LookInside
//
//  Phase C of multi-document support: NSDocument that wraps a `.lookin`
//  hierarchy archive on disk. Read-only by user intent; opening through
//  NSDocumentController integrates with Recent Documents, Open Recent,
//  proxy icon dragging, and Save As / Move to / Versions.
//

#import <Cocoa/Cocoa.h>

@class LookinHierarchyFile;

@interface LookinArchiveDocument : NSDocument

@property(nonatomic, strong) LookinHierarchyFile *hierarchyFile;

@end
