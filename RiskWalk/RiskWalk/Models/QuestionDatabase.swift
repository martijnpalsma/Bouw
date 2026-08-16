import Foundation

enum QuestionDatabase {
    static let businessTypes = [
        "Industrie / productie",
        "Metaalbewerking",
        "Houtbewerking",
        "Kunststofverwerking",
        "Voedingsmiddelenindustrie",
        "Visverwerking",
        "Bakkerij",
        "Horeca",
        "Hotel",
        "Zorginstelling",
        "Kantoor",
        "Winkel",
        "Supermarkt",
        "Opslag / warehouse",
        "Logistiek / transport",
        "Garage / autobedrijf",
        "Landbouw",
        "Agrarische opslag",
        "Bouwbedrijf",
        "Installatiebedrijf",
        "Chemische industrie",
        "Laboratorium",
        "Onderwijs",
        "Sportaccommodatie",
        "Recreatie",
        "Groepsaccommodatie",
        "Datacenter / IT",
        "Vastgoed / bedrijfsverzamelgebouw",
        "Afvalverwerking / recycling",
        "Anders"
    ]

    static let defaultTopicNames: [String] = [
        "Bedrijfsactiviteiten",
        "Gebouwen",
        "Constructie",
        "Compartimentering",
        "Elektrische installatie",
        "Verwarming",
        "Branddetectie",
        "Blusmiddelen",
        "Huishouding",
        "Roken/open vuur",
        "Accu's en laadplaatsen",
        "Gevaarlijke stoffen",
        "Machines/processen",
        "Opslag",
        "Buitenopslag",
        "Inbraak/diefstal",
        "Water",
        "Storm",
        "Bedrijfsschade",
        "Brandweer/repressie",
        "Openstaande vragen",
        "Tekortkomingen"
    ]

    static let allQuestions: [Question] = [
        Question(id: "activities_main", text: "Wat zijn de feitelijke bedrijfsactiviteiten?", type: .text, categories: ["Algemeen"], dependsOn: nil, requiresValue: nil),
        Question(id: "activities_onsite", text: "Welke werkzaamheden vinden op de locatie plaats?", type: .text, categories: ["Algemeen"], dependsOn: nil, requiresValue: nil),
        Question(id: "activities_third_party", text: "Welke activiteiten worden door derden uitgevoerd?", type: .text, categories: ["Algemeen"], dependsOn: nil, requiresValue: nil),

        Question(id: "building_construction", text: "Wat is de draagconstructie?", type: .text, categories: ["Algemeen"], dependsOn: nil, requiresValue: nil),
        Question(id: "building_facade", text: "Wat is de gevelconstructie?", type: .text, categories: ["Algemeen"], dependsOn: nil, requiresValue: nil),
        Question(id: "building_roof", text: "Wat is de dakconstructie?", type: .text, categories: ["Algemeen"], dependsOn: nil, requiresValue: nil),

        Question(id: "electrical_age", text: "Wat is de ouderdom van de installatie?", type: .text, categories: ["Algemeen"], dependsOn: nil, requiresValue: nil),
        Question(id: "electrical_maintenance", text: "Wordt onderhoud uitgevoerd?", type: .yesNo, categories: ["Algemeen"], dependsOn: nil, requiresValue: nil),

        Question(id: "accu_present", text: "Worden lithium-ion accu's geladen?", type: .yesNo, categories: ["Algemeen"], dependsOn: nil, requiresValue: nil),
        Question(id: "accu_count", text: "Aantal accu's", type: .number, categories: ["Algemeen"], dependsOn: "accu_present", requiresValue: "Ja"),
        Question(id: "accu_location", text: "Waar worden accu's geladen?", type: .text, categories: ["Algemeen"], dependsOn: "accu_present", requiresValue: "Ja"),
        Question(id: "accu_clearance", text: "Is minimaal 2 meter vrije ruimte aanwezig?", type: .yesNo, categories: ["Algemeen"], dependsOn: "accu_present", requiresValue: "Ja"),
        Question(id: "accu_detection", text: "Is detectie aanwezig?", type: .yesNo, categories: ["Algemeen"], dependsOn: "accu_present", requiresValue: "Ja"),
        Question(id: "accu_after_hours", text: "Vindt laden buiten werktijd plaats?", type: .yesNo, categories: ["Algemeen"], dependsOn: "accu_present", requiresValue: "Ja"),

        Question(id: "wood_dust_extraction", text: "Is houtstofafzuiging aanwezig?", type: .yesNo, categories: ["Houtbewerking"], dependsOn: nil, requiresValue: nil),
        Question(id: "wood_dust_location", text: "Waar staat de afzuiginstallatie?", type: .text, categories: ["Houtbewerking"], dependsOn: "wood_dust_extraction", requiresValue: "Ja"),
        Question(id: "wood_dust_cleaning", text: "Hoe vaak worden afzuigkanalen gereinigd?", type: .text, categories: ["Houtbewerking"], dependsOn: "wood_dust_extraction", requiresValue: "Ja"),

        Question(id: "metal_welding", text: "Wordt gelast, geslepen of gebrand?", type: .yesNo, categories: ["Metaalbewerking"], dependsOn: nil, requiresValue: nil),
        Question(id: "metal_gas_cylinders", text: "Zijn lasgassen aanwezig?", type: .yesNo, categories: ["Metaalbewerking"], dependsOn: "metal_welding", requiresValue: "Ja"),

        Question(id: "garage_ev_charging", text: "Worden elektrische voertuigen geladen?", type: .yesNo, categories: ["Garage / autobedrijf"], dependsOn: nil, requiresValue: nil),
        Question(id: "garage_tire_storage", text: "Zijn banden opgeslagen?", type: .yesNo, categories: ["Garage / autobedrijf"], dependsOn: nil, requiresValue: nil),
        Question(id: "garage_tire_count", text: "Hoeveel banden?", type: .number, categories: ["Garage / autobedrijf"], dependsOn: "garage_tire_storage", requiresValue: "Ja"),

        Question(id: "food_cooking", text: "Zijn bak-, frituur- of kookprocessen aanwezig?", type: .yesNo, categories: ["Voedingsmiddelenindustrie", "Horeca"], dependsOn: nil, requiresValue: nil),
        Question(id: "food_fryer", text: "Zijn frituurinstallaties aanwezig?", type: .yesNo, categories: ["Voedingsmiddelenindustrie", "Horeca"], dependsOn: nil, requiresValue: nil),

        Question(id: "hotel_rooms", text: "Hoeveel kamers/slaapplaatsen zijn aanwezig?", type: .number, categories: ["Hotel", "Groepsaccommodatie"], dependsOn: nil, requiresValue: nil),
        Question(id: "hotel_detection", text: "Zijn rookmelders of automatische detectie aanwezig?", type: .yesNo, categories: ["Hotel", "Groepsaccommodatie"], dependsOn: nil, requiresValue: nil),

        Question(id: "storage_height", text: "Tot welke hoogte worden goederen opgeslagen?", type: .text, categories: ["Opslag / warehouse"], dependsOn: nil, requiresValue: nil),
        Question(id: "storage_sprinkler", text: "Zijn sprinklerinstallaties aanwezig?", type: .yesNo, categories: ["Opslag / warehouse"], dependsOn: nil, requiresValue: nil),

        Question(id: "care_self_reliant", text: "Zijn bewoners of cliënten zelfredzaam?", type: .yesNo, categories: ["Zorginstelling"], dependsOn: nil, requiresValue: nil),
        Question(id: "care_evacuation", text: "Hoe wordt ontruiming georganiseerd?", type: .text, categories: ["Zorginstelling"], dependsOn: nil, requiresValue: nil)
    ]
}
