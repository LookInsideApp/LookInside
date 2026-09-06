//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

// Import the complete module before client categories so its model and signal
// types have the same module identity in Swift and Objective-C.
#import <LookInsideInspectionCore/LookInsideInspectionCore.h>

#import "LKPreferenceManager.h"
#import "LKMessageManager.h"
#import "LKHelper.h"
#import "LookinAttrIdentifiers.h"
#import "LookinAttrType.h"
#import "LookinAttribute.h"
#import "LookinAttributeModification.h"
#import "LookinAttributesGroup.h"
#import "LookinAttributesSection.h"
#import "LookinDashboardBlueprint.h"
#import "LookinDisplayItemDetail.h"
#import "LookinStaticAsyncUpdateTask.h"
#import "LookinDisplayItem.h"
#import "LookinAutoLayoutConstraint.h"
// Client-side display helpers (row title / subtitle, ancestor + subtree
// walks, class-chain predicates). The MCPBridge search route needs the
// same title and ancestry the inspector shows, and reimplementing them in
// Swift would fork the display logic.
#import "LookinDisplayItem+LookinClient.h"
#import "LookinObject.h"
#import "LookinAppInfo.h"
#import "LookinHierarchyInfo.h"
#import "LookinHierarchyFile.h"
#import "LookinArchiveDocument.h"
#import "LKReadWindowController.h"
#import "LKInspectableApp.h"
// The MCPBridge event publisher watches this manager's two RACSubjects
// (channelWillEnd, didReceivePush) to turn target disconnects and
// server-initiated pushes into bridge events. The channel type comes
// along because both signals carry one, and without the type visible
// Swift cannot see any API that mentions it -- including
// `-[LookinLiveDocumentController liveDocumentForChannel:]`.
#import "Lookin_PTChannel.h"
#import "LKConnectionManager.h"
#import "LKHierarchyDataSource.h"
#import "LKStaticHierarchyDataSource.h"
// The MCPBridge refresh route drives -reloadHierarchySignal, which lives on
// the window controller rather than the data source because the reload gate
// and the progress indicator it shares with the toolbar button are window
// state.
#import "LKStaticWindowController.h"
#import "LookinLiveDocument.h"
#import "LookinLiveDocumentController.h"
