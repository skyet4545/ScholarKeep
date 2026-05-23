import XCTest
@testable import ScholarKeep

final class DeviceWindowTests: XCTestCase {

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        var c = DateComponents()
        c.year = y; c.month = m; c.day = d; c.hour = 12
        return Calendar.current.date(from: c)!
    }

    func testNoDevicesMeansWindowClear() {
        let s = Student(displayName: "A", program: .pep, sfo: .stepUp)
        XCTAssertFalse(DeviceWindowChecker.studentHasRecentDevice(student: s, within: 2, asOf: .now))
    }

    func testDeviceWithinWindowFlags() {
        let s = Student(displayName: "A", program: .pep, sfo: .stepUp)
        let device = DevicePurchase(deviceType: "iPad",
                                    purchaseDate: date(2026, 1, 1),
                                    amount: 600,
                                    student: s)
        s.devicePurchases.append(device)
        XCTAssertTrue(DeviceWindowChecker.studentHasRecentDevice(student: s, within: 2, asOf: date(2026, 6, 1)))
    }

    func testDeviceOlderThanWindowOK() {
        let s = Student(displayName: "A", program: .pep, sfo: .stepUp)
        let device = DevicePurchase(deviceType: "iPad",
                                    purchaseDate: date(2023, 1, 1),
                                    amount: 600,
                                    student: s)
        s.devicePurchases.append(device)
        XCTAssertFalse(DeviceWindowChecker.studentHasRecentDevice(student: s, within: 2, asOf: date(2026, 6, 1)))
    }

    func testMultipleDevicesUsesMostRecent() {
        let s = Student(displayName: "A", program: .pep, sfo: .stepUp)
        s.devicePurchases.append(DevicePurchase(deviceType: "Old Chromebook",
                                                purchaseDate: date(2022, 1, 1),
                                                amount: 300, student: s))
        s.devicePurchases.append(DevicePurchase(deviceType: "Recent iPad",
                                                purchaseDate: date(2026, 2, 1),
                                                amount: 600, student: s))
        XCTAssertTrue(DeviceWindowChecker.studentHasRecentDevice(student: s, within: 2, asOf: date(2026, 6, 1)))
    }

    func testNextEligibleDateAdvances2Years() {
        let d = DevicePurchase(deviceType: "iPad",
                               purchaseDate: date(2026, 1, 1),
                               amount: 600)
        let next = d.nextEligibleDate(years: 2)
        XCTAssertEqual(Calendar.current.component(.year, from: next), 2028)
        XCTAssertEqual(Calendar.current.component(.month, from: next), 1)
        XCTAssertEqual(Calendar.current.component(.day, from: next), 1)
    }
}
