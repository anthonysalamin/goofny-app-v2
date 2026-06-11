import SwiftUI

struct FilterSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: FeedFilters
    let onApply: (FeedFilters) -> Void

    init(filters: FeedFilters, onApply: @escaping (FeedFilters) -> Void) {
        _draft = State(initialValue: filters)
        self.onApply = onApply
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Species") {
                    Picker("Species", selection: $draft.species) {
                        Text("Any").tag(Species?.none)
                        ForEach(Species.allCases) { species in
                            Text("\(species.emoji) \(species.label)").tag(Species?.some(species))
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Sex") {
                    Picker("Sex", selection: $draft.sex) {
                        Text("Any").tag(Sex?.none)
                        ForEach(Sex.allCases) { sex in
                            Text("\(sex.symbol) \(sex.label)").tag(Sex?.some(sex))
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Location") {
                    Picker("Country", selection: $draft.country) {
                        Text("Any country").tag(String?.none)
                        ForEach(Country.all, id: \.code) { country in
                            Text("\(Country.flag(for: country.code)) \(country.name)")
                                .tag(String?.some(country.code))
                        }
                    }
                    TextField("City", text: $draft.city)
                }

                Section("Breed") {
                    TextField("Breed (e.g. Corgi)", text: $draft.breed)
                }

                Section {
                    Button("Clear all filters", role: .destructive) {
                        let search = draft.searchText
                        draft = .none
                        draft.searchText = search
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply(draft)
                        dismiss()
                    }
                    .bold()
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
