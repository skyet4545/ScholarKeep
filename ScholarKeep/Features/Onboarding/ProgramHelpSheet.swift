import SwiftUI

/// Educational sheet that helps a parent figure out which Florida ESA program
/// they actually have. Tapping "This is mine" sets the program and dismisses.
struct ProgramHelpSheet: View {
    @Binding var program: Program
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Not sure which scholarship is yours? Match the description below.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    card(
                        program: .fesUA,
                        emoji: "🧩",
                        title: "FES-UA",
                        subtitle: "Family Empowerment — Unique Abilities",
                        bullets: [
                            "Your child has an IEP, 504 plan, or qualifying diagnosis",
                            "Up to ~$10K per year, no income cap",
                            "Largest category list (therapy, curriculum, devices, tuition)"
                        ]
                    )

                    card(
                        program: .fesEO,
                        emoji: "🎒",
                        title: "FES-EO",
                        subtitle: "Family Empowerment — Educational Options",
                        bullets: [
                            "Universal school-choice voucher (formerly the Tax Credit Scholarship)",
                            "Used for private-school tuition; reimbursements for fees/uniforms/etc",
                            "Tuition is usually paid direct to the school"
                        ]
                    )

                    card(
                        program: .pep,
                        emoji: "🏠",
                        title: "PEP",
                        subtitle: "Personalized Education Program (homeschool)",
                        bullets: [
                            "Homeschool families who registered through Step Up's PEP",
                            "Requires an approved Student Learning Plan (SLP) before purchases count",
                            "Up to ~$8K per year; devices are NOT eligible"
                        ]
                    )

                    Text("Still unsure? Check your acceptance email from Step Up or AAA — the program name is on the first line.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                }
                .padding(20)
            }
            .navigationTitle("Pick your program")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func card(program target: Program, emoji: String, title: String, subtitle: String, bullets: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(emoji).font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
            }
            ForEach(bullets, id: \.self) { b in
                HStack(alignment: .top, spacing: 6) {
                    Text("•").foregroundStyle(.secondary)
                    Text(b).font(.subheadline)
                }
            }
            Button {
                program = target
                dismiss()
            } label: {
                Text("This is mine")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
    }
}
