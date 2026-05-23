import Foundation
import SwiftData

@Model
final class Student {
    @Attribute(.unique) var id: UUID
    var displayName: String
    var programRaw: String
    var sfoRaw: String
    var gradeLevel: String
    var county: String
    var schoolYear: String
    var awardAmount: Decimal?
    var notes: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        displayName: String,
        program: Program,
        sfo: SFO,
        gradeLevel: String = "",
        county: String = "",
        schoolYear: String = SchoolYear.label(),
        awardAmount: Decimal? = nil,
        notes: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.displayName = displayName
        self.programRaw = program.rawValue
        self.sfoRaw = sfo.rawValue
        self.gradeLevel = gradeLevel
        self.county = county
        self.schoolYear = schoolYear
        self.awardAmount = awardAmount
        self.notes = notes
        self.createdAt = createdAt
    }

    var program: Program {
        get { Program(rawValue: programRaw) ?? .fesUA }
        set { programRaw = newValue.rawValue }
    }

    var sfo: SFO {
        get { SFO(rawValue: sfoRaw) ?? .stepUp }
        set { sfoRaw = newValue.rawValue }
    }
}
