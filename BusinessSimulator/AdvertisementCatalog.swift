import Foundation

struct AdvertisementCatalog {
    let noAdvertisement: Advertisement

    init() {
        noAdvertisement = Advertisement(
            id: AdvertisementID(rawValue: "none"),
            name: "No Advertisement",
            smallIcon: .system("speaker.slash.fill"),
            description: "Your business currently relies on word of mouth.",
            price: 0,
            paymentSchedule: .oneTime,
            demandLevel: 0,
            marketSizeLevel: 0
        )
    }
}
