import Foundation

/// A vaccine type with its default protection duration and plain-English guidance.
struct VaccineInfo: Identifiable, Hashable {
    let name: String
    let defaultMonths: Int
    /// Shown as guidance when the real-world duration varies (e.g. local rabies rules).
    let durationNote: String?
    /// One plain-English sentence describing what the vaccine does.
    let description: String
    /// Illnesses this vaccine helps protect against.
    let diseasesCovered: [String]

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
        VaccineInfo(
            name: "DHPP",
            defaultMonths: 36,
            durationNote: "Typically ~3 years",
            description: "A core shot that helps protect your dog from several serious illnesses.",
            diseasesCovered: ["Distemper", "Hepatitis", "Parainfluenza", "Parvovirus"]
        ),
        VaccineInfo(
            name: "Rabies",
            defaultMonths: 12,
            durationNote: "1–3 years depending on local rules",
            description: "Required in many places and helps protect your dog from rabies.",
            diseasesCovered: ["Rabies"]
        ),
        VaccineInfo(
            name: "Bordetella",
            defaultMonths: 12,
            durationNote: "6–12 months",
            description: "Helps prevent kennel cough, a contagious cough dogs can catch around other dogs.",
            diseasesCovered: ["Kennel cough"]
        ),
        VaccineInfo(
            name: "Leptospirosis",
            defaultMonths: 12,
            durationNote: "~12 months",
            description: "Helps protect your dog from a bacterial infection picked up from water or infected animals.",
            diseasesCovered: ["Leptospirosis"]
        ),
        VaccineInfo(
            name: "Lyme Disease",
            defaultMonths: 12,
            durationNote: "~12 months",
            description: "Helps protect your dog from Lyme disease, which spreads through tick bites.",
            diseasesCovered: ["Lyme disease"]
        ),
        VaccineInfo(
            name: "Canine Influenza",
            defaultMonths: 12,
            durationNote: "~12 months",
            description: "Helps protect your dog from dog flu, a contagious respiratory illness.",
            diseasesCovered: ["Canine influenza"]
        )
    ]

    static let cat: [VaccineInfo] = [
        VaccineInfo(
            name: "FVRCP",
            defaultMonths: 36,
            durationNote: "Typically ~3 years",
            description: "A core shot that helps protect your cat from several common and serious illnesses.",
            diseasesCovered: ["Feline viral rhinotracheitis", "Calicivirus", "Panleukopenia"]
        ),
        VaccineInfo(
            name: "Rabies",
            defaultMonths: 12,
            durationNote: "1–3 years depending on local rules",
            description: "Required in many places and helps protect your cat from rabies.",
            diseasesCovered: ["Rabies"]
        ),
        VaccineInfo(
            name: "FeLV",
            defaultMonths: 12,
            durationNote: "~12 months",
            description: "Helps protect your cat from feline leukemia, a virus that weakens the immune system.",
            diseasesCovered: ["Feline leukemia"]
        ),
        VaccineInfo(
            name: "FIV",
            defaultMonths: 12,
            durationNote: "~12 months, where used",
            description: "Helps protect your cat from feline immunodeficiency virus, which affects the immune system.",
            diseasesCovered: ["Feline immunodeficiency virus"]
        ),
        VaccineInfo(
            name: "Chlamydia",
            defaultMonths: 12,
            durationNote: "~12 months",
            description: "Helps protect your cat from a bacterial infection that can affect the eyes and breathing.",
            diseasesCovered: ["Chlamydia"]
        )
    ]

    static func list(for species: Species) -> [VaccineInfo] {
        species == .dog ? dog : cat
    }

    static func info(name: String, species: Species) -> VaccineInfo? {
        list(for: species).first { $0.name == name }
    }
}
