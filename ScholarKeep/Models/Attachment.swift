import Foundation
import SwiftData

@Model
final class Attachment {
    @Attribute(.unique) var id: UUID
    var typeRaw: String
    var mimeType: String
    @Attribute(.externalStorage) var fileData: Data?
    var ocrText: String
    var createdAt: Date
    var expense: Expense?

    init(
        id: UUID = UUID(),
        type: AttachmentType,
        mimeType: String,
        fileData: Data? = nil,
        ocrText: String = "",
        createdAt: Date = .now,
        expense: Expense? = nil
    ) {
        self.id = id
        self.typeRaw = type.rawValue
        self.mimeType = mimeType
        self.fileData = fileData
        self.ocrText = ocrText
        self.createdAt = createdAt
        self.expense = expense
    }

    var type: AttachmentType {
        get { AttachmentType(rawValue: typeRaw) ?? .other }
        set { typeRaw = newValue.rawValue }
    }
}
