import SwiftUI
import SwiftData

struct ExpenseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings
    @Query(sort: \Expense.purchaseDate, order: .reverse) private var allExpenses: [Expense]
    @Query(sort: \Student.createdAt) private var students: [Student]

    @State private var showCapture = false
    @State private var capturingSource: CaptureFlowView.Source = .scanner
    @State private var showManual = false

    private var activeStudent: Student? {
        guard let id = settings.activeStudentID else { return students.first }
        return students.first { $0.id == id }
    }

    private var expenses: [Expense] {
        guard let s = activeStudent else { return [] }
        return allExpenses.filter { $0.student?.id == s.id }
    }

    var body: some View {
        NavigationStack {
            List {
                if let student = activeStudent {
                    Section {
                        Text("Showing expenses for \(student.displayName).")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                ForEach(expenses) { expense in
                    NavigationLink {
                        ExpenseDetailView(expense: expense)
                    } label: {
                        ExpenseRow(expense: expense)
                    }
                }
                .onDelete(perform: delete)
            }
            .overlay {
                if expenses.isEmpty {
                    ContentUnavailableView {
                        Label("No expenses yet", systemImage: "doc.text.viewfinder")
                    } description: {
                        Text("Scan or add your first receipt.")
                    } actions: {
                        Button("Scan a receipt") { startCapture(.scanner) }
                            .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("Expenses")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button { startCapture(.scanner) } label: { Label("Scan receipt", systemImage: "doc.text.viewfinder") }
                        Button { startCapture(.photoLibrary) } label: { Label("Pick from library", systemImage: "photo.on.rectangle") }
                        Button { showManual = true } label: { Label("Add manually", systemImage: "square.and.pencil") }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(activeStudent == nil)
                }
            }
            .sheet(isPresented: $showCapture) {
                if let student = activeStudent {
                    CaptureFlowView(student: student, source: capturingSource)
                }
            }
            .sheet(isPresented: $showManual) {
                if let student = activeStudent {
                    ExpenseReviewView(
                        scannedImages: [],
                        parsed: ParsedReceipt(),
                        rawOCRText: "",
                        student: student
                    )
                }
            }
        }
    }

    private func startCapture(_ src: CaptureFlowView.Source) {
        capturingSource = src
        showCapture = true
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(expenses[index])
        }
        try? modelContext.save()
    }
}

private struct ExpenseRow: View {
    let expense: Expense

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(expense.vendorName.isEmpty ? "Untitled vendor" : expense.vendorName)
                    .font(.headline)
                Spacer()
                Text(expense.total.formatted(.currency(code: expense.currency)))
                    .font(.subheadline.monospacedDigit())
            }
            HStack(spacing: 6) {
                Text(expense.purchaseDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let status = expense.eligibilityResult {
                    EligibilityChip(status: status)
                }
                if expense.requiresPreAuth {
                    Text("Pre-auth")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.15), in: Capsule())
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
