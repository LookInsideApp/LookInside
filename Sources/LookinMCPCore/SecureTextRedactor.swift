import Foundation
import LookinCore

/// Centralized redaction for secure text fields. Applied by `JSONShape.node` so any
/// tool that surfaces an element's text inherits the protection automatically.
///
/// The check is conservative: we strip text whenever the class is `UITextField` /
/// `NSSecureTextField` AND the `isSecureTextEntry` (UIKit) or class name itself
/// (`NSSecureTextField`) indicates secure entry. Better to over-redact than to leak.
public struct SecureTextRedactor {
    public init() {}

    public func isSecure(item: LookinDisplayItem) -> Bool {
        let className = JSONShape.primaryClassName(item)
        if className == "NSSecureTextField" { return true }
        if className == "UITextField" {
            if let secure = JSONShape.extractAttribute(item, identifier: "isSecureTextEntry") as? NSNumber, secure.boolValue {
                return true
            }
        }
        // Cover subclasses by checking the full chain.
        let chain = (item.viewObject?.classChainList as? [String]) ?? []
        if chain.contains("NSSecureTextField") { return true }
        return false
    }
}
