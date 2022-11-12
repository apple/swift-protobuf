import XCTest
@testable import GenTests
import bgenerated
import generated

final class GenTestsTests: XCTestCase {
    static let uuid = UUID()
    static let noUuid = "DNSADO234123ASD"

    func generateBGenerated() -> bgenerated.Money_Order {
        return bgenerated
                .Money_Order
                .construct(
                gender: .female,
                genders: [.female, .other],
                currency: .construct(c: .amount(1)),
                oCurrency: nil,
                currencies: [.construct(c: .valuta(bgenerated.Money_Valuta.euro))],
                uuid: GenTestsTests.uuid,
                noUuid: GenTestsTests.noUuid,
                noUuids: [GenTestsTests.noUuid],
                repeatedUuids: [GenTestsTests.uuid, GenTestsTests.uuid],
                orderInner: .innerAnother,
                orderInners: [.innerAnother2],
                something: .alsoUuid(GenTestsTests.uuid)
        )
    }

    func generateGenerated() -> generated.Money_Order {
        return generated.Money_Order.with({ moneyOrder in
            moneyOrder.gender = .female
            moneyOrder.genders = [.female, .other]
            moneyOrder.currency = generated.Money_Currency.with({ currency in
                currency.amount = 1
            })
            moneyOrder.currencies = [generated.Money_Currency.with({ currency in
                currency.valuta = .euro
            })]
            moneyOrder.uuid = GenTestsTests.uuid.uuidString
            moneyOrder.noUuid = GenTestsTests.noUuid
            moneyOrder.noUuids = [GenTestsTests.noUuid]
            moneyOrder.repeatedUuids = [GenTestsTests.uuid.uuidString, GenTestsTests.uuid.uuidString]
            moneyOrder.orderInner = .innerAnother
            moneyOrder.orderInners = [.innerAnother2]
            moneyOrder.something = .alsoUuid(GenTestsTests.uuid.uuidString)
        })
    }

    func testEqual() {
        let bGenerated = generateBGenerated()
        let gen = generateGenerated()

        let bGeneratedData = try! bGenerated.serializedData()
        let genData = try! gen.serializedData()

        XCTAssertEqual(bGeneratedData, genData)

        let bGeneratedFromGenData = try! bgenerated.Money_Order.init(serializedBytes: genData)

        XCTAssertEqual(bGenerated, bGeneratedFromGenData)

        let genFromBGeneratedData = try! generated.Money_Order.init(serializedBytes: bGeneratedData)

        XCTAssertEqual(gen, genFromBGeneratedData)
    }

    func failingTest(changeGen: (inout generated.Money_Order) -> ()) {
        var gen = generateGenerated()

        // First verify it works the way it is generated standardly
        let _ = try! bgenerated.Money_Order(serializedBytes: try! gen.serializedData())

        changeGen(&gen)

        let data = try! gen.serializedData()

        XCTAssertThrowsError(try bgenerated.Money_Order.init(serializedBytes: data))
    }

    func testFailNoUuid() {
        failingTest { $0.uuid = GenTestsTests.noUuid }
    }

    func testFailWrongRepeatedUUID() {
        failingTest { $0.repeatedUuids = [GenTestsTests.uuid.uuidString, GenTestsTests.noUuid] }
    }

    func testFailFirstEnumCase() {
        failingTest { $0.gender = .male }
    }

    func testFailFirstEnumCaseRepeated() {
        failingTest { $0.genders = [.female, .male] }
    }

    func testFailRequiredPropertyNil() {
        failingTest { $0.clearCurrency() }
    }

    func testFailNotRecognized() {
        failingTest { $0.gender = .UNRECOGNIZED(5) }
    }

    func testFailInnerUuid() {
        failingTest { $0.something = .alsoUuid(GenTestsTests.noUuid) }
    }

    static var allTests = [
        ("testEqual", testEqual),
        ("testFailNoUuid", testFailNoUuid),
        ("testFailWrongRepeatedUUID", testFailWrongRepeatedUUID),
        ("testFailFirstEnumCase", testFailFirstEnumCase),
        ("testFailFirstEnumCaseRepeated", testFailFirstEnumCaseRepeated),
        ("testFailRequiredPropertyNil", testFailRequiredPropertyNil),
        ("testFailNotRecognized", testFailNotRecognized),
        ("testFailInnerUuid", testFailInnerUuid),
    ]
}
