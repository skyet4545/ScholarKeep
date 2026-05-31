import Foundation
import SwiftData

@Model
final class Attachment {
    var id: UUID = UUID()
    var typeRaw: String = AttachmentType.other.rawValue
    var mimeType: String = ""
    @Attribute(.externalStorage) var fileData: Data?
    var ocrText: String = ""
    var createdAt: Date = Date.now
    var expense: Expense?

    init(
        id: UUID = UUID(),
        type: AttachmentType,
        mimeType: String,
        fileData: Data? = nil,
        ocrText: String = "",
        createdAt: Date = Date.now,
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
