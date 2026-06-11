import Foundation

/// A vaccine type with its default protection duration.
struct VaccineInfo: Identifiable, Hashable {
    let name: String
    let defaultMonths: Int
    /// Shown as guidance when the real-world duration varies (e.g. local rabies rules).
    let durationNote: String?

    var id: String { name }

    var defaultDurationLabel: String {
        VaccineInfo.durationLabel(months: defaultMonths)
    }

    static func durationLabel(months: Int) -> String {
        if months % 12 == 0 {
            let years = months / 12
            return "\(years) year\(years == 1 ? "" : "s")"
        }
        return "\(months) month\(months == 1 ? "" : "s")"
    }
}

/// Predefined, species-specific vaccine lists with veterinary defaults.
enum VaccineCatalog {
    static let dog: [VaccineInfo] = [
        VaccineInfo(name: "DHPP", defaultMonths: 36, durationNote: "Typically ~3 years"),
        VaccineInfo(name: "Rabies", defaultMonths: 12, durationNote: "1–3 years depending on local rules"),
        VaccineInfo(name: "Bordetella", defaultMonths: 12, durationNote: "6–12 months"),
        VaccineInfo(name: "Leptospirosis", defaultMonths: 12, durationNote: "~12 months"),
        VaccineInfo(name: "Lyme Disease", defaultMonths: 12, durationNote: "~12 months"),
        VaccineInfo(name: "Canine Influenza", defaultMonths: 12, durationNote: "~12 months")
    ]

    static let cat: [VaccineInfo] = [
        VaccineInfo(name: "FVRCP", defaultMonths: 36, durationNote: "Typically ~3 years"),
        VaccineInfo(name: "Rabies", defaultMonths: 12, durationNote: "1–3 years depending on local rules"),
        VaccineInfo(name: "FeLV", defaultMonths: 12, durationNote: "~12 months"),
        VaccineInfo(name: "FIV", defaultMonths: 12, durationNote: "~12 months, where used"),
        VaccineInfo(name: "Chlamydia", defaultMonths: 12, durationNote: "~12 months")
    ]

    static func list(for species: Species) -> [VaccineInfo] {
        species == .dog ? dog : cat
    }

    static func info(name: String, species: Species) -> VaccineInfo? {
        list(for: species).first { $0.name == name }
    }
}
