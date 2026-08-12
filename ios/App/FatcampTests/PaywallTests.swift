import XCTest
import StoreKitTest

/// Guards the paywall's StoreKit configuration — the contract between
/// Products.storekit, the production product IDs the app sells, and App
/// Store Connect.
///
/// Why these tests stop short of executing a purchase: purchase execution
/// needs an app identity. Hosted in the Fatcamp app, SKTestSession's init
/// deadlocks against the webview's boot-time StoreKit calls; hostless, the
/// StoreKit daemon refuses purchases outright (SKInternalErrorDomain 3).
/// Both were reproduced repeatedly before settling here. The purchase sheet
/// itself is a two-minute manual check: run the app from Xcode with the
/// scheme's StoreKit configuration, buy Pro in Profile → The plan, and watch
/// the movement cap drop — Debug → StoreKit → Manage Transactions covers
/// refunds and expiry.
final class PaywallTests: XCTestCase {

    /// The IDs the app sells. If these drift from index.html's IAP map or
    /// from App Store Connect, the paywall silently sells nothing.
    private let proID = "com.frennat.fatcamp.pro.monthly"
    private let maxID = "com.frennat.fatcamp.max.monthly"

    private func configJSON() throws -> [String: Any] {
        let url = try XCTUnwrap(Bundle(for: PaywallTests.self)
            .url(forResource: "Products", withExtension: "storekit"),
            "Products.storekit must ship inside the test bundle")
        let data = try Data(contentsOf: url)
        return try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    func testConfigurationDefinesBothTiers() throws {
        let root = try configJSON()
        let groups = try XCTUnwrap(root["subscriptionGroups"] as? [[String: Any]])
        XCTAssertEqual(groups.count, 1, "one subscription group, matching App Store Connect")

        let subs = try XCTUnwrap(groups[0]["subscriptions"] as? [[String: Any]])
        let byID = Dictionary(uniqueKeysWithValues: subs.map { ($0["productID"] as! String, $0) })
        XCTAssertEqual(Set(byID.keys), [proID, maxID],
                       "the configuration must sell exactly the two production IDs")

        let pro = byID[proID]!, max = byID[maxID]!
        XCTAssertEqual(pro["displayPrice"] as? String, "9.99")
        XCTAssertEqual(max["displayPrice"] as? String, "14.99")
        XCTAssertEqual(pro["recurringSubscriptionPeriod"] as? String, "P1M")
        XCTAssertEqual(max["recurringSubscriptionPeriod"] as? String, "P1M")
        XCTAssertEqual(pro["groupNumber"] as? Int, 1, "Pro is the lower tier")
        XCTAssertEqual(max["groupNumber"] as? Int, 2, "Max ranks above Pro in the group")

        let groupID = groups[0]["id"] as? String
        XCTAssertEqual(pro["subscriptionGroupID"] as? String, groupID)
        XCTAssertEqual(max["subscriptionGroupID"] as? String, groupID)
    }

    func testStoreKitAcceptsTheConfiguration() throws {
        // init throws on a file StoreKit cannot parse — this is the gate that
        // catches a malformed edit before it reaches an Xcode run
        let session = try SKTestSession(configurationFileNamed: "Products")
        session.disableDialogs = true
        XCTAssertNotNil(session)
    }

    func testUnknownProductDoesNotSell() async throws {
        let session = try SKTestSession(configurationFileNamed: "Products")
        session.disableDialogs = true
        session.clearTransactions()
        do {
            try await session.buyProduct(productIdentifier: "com.frennat.fatcamp.nope")
            XCTFail("a product the configuration does not define must not sell")
        } catch {
            // rejected, as it should be
        }
    }
}
