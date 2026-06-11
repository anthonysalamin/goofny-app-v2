import SwiftUI

/// Searchable breed list — start typing to filter, tap to select.
struct BreedPickerView: View {
    let species: Species
    @Binding var selection: String
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filteredBreeds: [String] {
        let all = Breeds.list(for: species)
        guard !searchText.isEmpty else { return all }
        return all.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List {
            if filteredBreeds.isEmpty {
                Text("No breed matches \"\(searchText)\"")
                    .foregroundStyle(.secondary)
            }
            ForEach(filteredBreeds, id: \.self) { breed in
                Button {
                    selection = breed
                    dismiss()
                } label: {
                    HStack {
                        Text(breed).foregroundStyle(.primary)
                        Spacer()
                        if breed == selection {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }
        }
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search \(species.label.lowercased()) breeds"
        )
        .navigationTitle("Breed")
        .navigationBarTitleDisplayMode(.inline)
    }
}
