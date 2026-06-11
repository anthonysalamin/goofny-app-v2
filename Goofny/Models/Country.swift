import Foundation

/// ISO 3166-1 alpha-2 country helper built from the system locale database.
enum Country {
    /// All ISO region codes with localized names, sorted alphabetically.
    static let all: [(code: String, name: String)] = {
        Locale.Region.isoRegions
            .map(\.identifier)
            .filter { $0.count == 2 }
            .compactMap { code -> (String, String)? in
                guard let name = Locale.current.localizedString(forRegionCode: code) else { return nil }
                return (code, name)
            }
            .sorted { $0.1 < $1.1 }
    }()

    static func name(for code: String) -> String {
        Locale.current.localizedString(forRegionCode: code) ?? code
    }

    static func flag(for code: String) -> String {
        code.uppercased().unicodeScalars.reduce(into: "") { result, scalar in
            if let flagScalar = UnicodeScalar(127397 + scalar.value) {
                result.unicodeScalars.append(flagScalar)
            }
        }
    }
}

/// Common breeds for the Add/Edit pet form pickers.
enum Breeds {
    static let dog: [String] = [
        "Australian Shepherd", "Beagle", "Bernese Mountain Dog", "Border Collie",
        "Boxer", "Bulldog", "Chihuahua", "Cocker Spaniel", "Corgi", "Dachshund",
        "Dalmatian", "Doberman", "French Bulldog", "German Shepherd",
        "Golden Retriever", "Great Dane", "Husky", "Jack Russell Terrier",
        "Labrador Retriever", "Maltese", "Mixed Breed", "Pomeranian", "Poodle",
        "Pug", "Rottweiler", "Samoyed", "Shiba Inu", "Shih Tzu",
        "Yorkshire Terrier", "Other"
    ]

    static let cat: [String] = [
        "Abyssinian", "Bengal", "Birman", "British Shorthair", "Burmese",
        "Devon Rex", "Domestic Shorthair", "Exotic Shorthair", "Maine Coon",
        "Mixed Breed", "Munchkin", "Norwegian Forest Cat", "Persian", "Ragdoll",
        "Russian Blue", "Scottish Fold", "Siamese", "Siberian", "Sphynx", "Other"
    ]

    static func list(for species: Species) -> [String] {
        species == .dog ? dog : cat
    }
}
