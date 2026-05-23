import SwiftUI

struct CategoryPickerView: View {
    @Binding var selection: String?
    let student: Student

    private var categories: [RuleCategory] {
        guard let rs = RulesetLoader.shared.ruleset else { return [] }
        return rs.categories.filter { $0.applies(toProgram: student.program) }
    }

    var body: some View {
        Picker("Category", selection: $selection) {
            Text("Auto-detect").tag(String?.none)
            ForEach(categories) { cat in
                Text(cat.displayName).tag(String?.some(cat.key))
            }
        }
    }
}
