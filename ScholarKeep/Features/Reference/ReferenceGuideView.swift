import SwiftUI

struct ReferenceGuideView: View {
    @State private var searchText: String = ""

    var body: some View {
        NavigationStack {
            List {
                if let rs = RulesetLoader.shared.ruleset {
                    Section {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Florida ESA — \(rs.schoolYear)").font(.title3.bold())
                            Text("Ruleset version: \(rs.sourceVersion) · Updated \(rs.lastUpdated)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(rs.disclaimer).font(.caption2).foregroundStyle(.secondary)
                        }
                    }

                    Section("Deadlines") {
                        LabeledContent("Spending window", value: "July 1 – June 30")
                        LabeledContent("Submission deadline", value: "July 31 (after school year)")
                        LabeledContent("On-hold clock", value: "\(rs.deadlines.onHoldDays) days")
                        LabeledContent("Review window", value: "Up to \(rs.deadlines.reviewDaysMax) days")
                    }

                    Section("Global rules") {
                        LabeledContent("Device replacement", value: "1 every \(rs.globalRules.deviceReplacementYears) years")
                        LabeledContent("Peripheral pre-auth", value: "Over \(rs.globalRules.peripheralPreAuthOver.formatted(.currency(code: "USD")))")
                        LabeledContent("FES-UA balance cap", value: "No new funding above \(rs.globalRules.balanceCapNoNewFundingFESUA.formatted(.currency(code: "USD")))")
                    }

                    ForEach(filteredCategories(rs.categories)) { cat in
                        Section(cat.displayName) {
                            HStack(spacing: 8) {
                                Image(systemName: cat.baseEligibility.systemImageName)
                                    .foregroundStyle(.tint)
                                Text(cat.baseEligibility.displayName).font(.subheadline)
                            }
                            Text("Programs: \(cat.programs.joined(separator: ", "))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if !cat.keywords.isEmpty {
                                Text("Keywords: \(cat.keywords.joined(separator: ", "))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if let caps = cat.caps, let max = caps.maxAmount {
                                LabeledContent("Cap", value: max.formatted(.currency(code: "USD")))
                            }
                            if cat.requiresStudentName == true { Label("Student name on receipt", systemImage: "person.text.rectangle").font(.caption) }
                            if cat.requiresProviderCredentials == true { Label("Provider credentials required", systemImage: "checkmark.seal").font(.caption) }
                            if cat.requiresEducationalBenefitForm == true { Label("Educational Benefit Form required", systemImage: "doc.badge.gearshape").font(.caption) }
                            if let notes = cat.notes { Text(notes).font(.caption2).foregroundStyle(.secondary) }
                            Text(cat.sourceCitation).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                } else if let err = RulesetLoader.shared.loadError {
                    Section { Text("Couldn't load ruleset: \(err.localizedDescription)").foregroundStyle(.red) }
                }

                Section {
                    DisclosureGroup("Source links") {
                        Link("Step Up — FES-UA", destination: URL(string: "https://www.stepupforstudents.org/scholarships/unique-abilities/")!)
                        Link("Step Up — PEP", destination: URL(string: "https://www.stepupforstudents.org/scholarships/personalized-education-program/")!)
                        Link("FES-UA Purchasing Guide", destination: URL(string: "https://go.stepupforstudents.org/hubfs/GUIDES/FES-UA-Purchasing-Guide.pdf")!)
                        Link("PEP Purchasing Guide", destination: URL(string: "https://go.stepupforstudents.org/hubfs/GUIDES/PEP-Purchasing-Guide.pdf")!)
                        Link("Reimbursement how-to", destination: URL(string: "https://go.stepupforstudents.org/hubfs/Scholarship%20Info/Reimbursement-How-to-Submit-Final.pdf")!)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search categories")
            .scrollContentBackground(.hidden)
            .background(DS.canvas)
            .navigationTitle("Reference")
        }
    }

    private func filteredCategories(_ cats: [RuleCategory]) -> [RuleCategory] {
        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return cats }
        return cats.filter {
            $0.displayName.lowercased().contains(q) || $0.keywords.contains(where: { $0.lowercased().contains(q) })
        }
    }
}
