import Foundation

struct AdvertisementCatalog {
    let noAdvertisement: Advertisement
    let canvassing: Advertisement
    let neighborhoodFlyers: Advertisement
    let clubhouseAdvertisement: Advertisement
    let blockPartySponsorship: Advertisement
    let neighborhoodGazetteAdvertisement: Advertisement
    let townNewspaperAdvertisement: Advertisement
    let socialMediaAdvertisement: Advertisement
    let beachVolleyballSponsorship: Advertisement
    let youthBaseballSponsorship: Advertisement
    let harvestEventSponsorship: Advertisement
    let sportsPodcastPartnership: Advertisement
    let fitnessInfluencerPartnership: Advertisement
    let gardeningPodcastPartnership: Advertisement
    let billboardAdvertisement: Advertisement
    let radioAdvertisement: Advertisement

    let tierZero: AdvertisementTier
    let tierOne: AdvertisementTier
    let tierTwo: AdvertisementTier
    let tierThree: AdvertisementTier
    let smoothieTierFour: AdvertisementTier
    let hotDogTierFour: AdvertisementTier
    let pieTierFour: AdvertisementTier
    let tierFive: AdvertisementTier

    var tiersByProduct: [ProductID: [AdvertisementTier]] {
        [
            .smoothies: [
                tierZero,
                tierOne,
                tierTwo,
                tierThree,
                smoothieTierFour,
                tierFive
            ],
            .hotDogs: [
                tierZero,
                tierOne,
                tierTwo,
                tierThree,
                hotDogTierFour,
                tierFive
            ],
            .pies: [
                tierZero,
                tierOne,
                tierTwo,
                tierThree,
                pieTierFour,
                tierFive
            ]
        ]
    }

    init() {
        let noAdvertisement = Advertisement(
            id: AdvertisementID(rawValue: "none"),
            name: "No Advertisement",
            smallIcon: .system("speaker.slash.fill"),
            description: "Your business currently relies on word of mouth.",
            price: 0,
            paymentSchedule: .oneTime,
            demandLevel: 0,
            marketSizeLevel: 0
        )
        self.noAdvertisement = noAdvertisement

        canvassing = Advertisement(
            id: AdvertisementID(rawValue: "canvassing"),
            name: "Door-to-Door Canvassing",
            smallIcon: .system("door.left.hand.open"),
            description: "Spend time introducing your business to the neighborhood.",
            paymentSchedule: .oneTime,
            demandLevel: 2,
            marketSizeLevel: 1,
            dailyTimeRequired: 0.5
        )

        neighborhoodFlyers = Advertisement(
            id: AdvertisementID(rawValue: "neighborhood-flyers"),
            name: "Neighborhood Flyers",
            smallIcon: .system("doc.text.image.fill"),
            description: "Hang flyers around the neighborhood to promote your business.",
            paymentSchedule: .oneTime,
            demandLevel: 1,
            marketSizeLevel: 1
        )

        clubhouseAdvertisement = Advertisement(
            id: AdvertisementID(rawValue: "clubhouse-advertisement"),
            name: "Neighborhood Clubhouse Ad",
            smallIcon: .system("building.2.fill"),
            description: "Pay for weekly advertising space in the neighborhood clubhouse.",
            paymentSchedule: .weekly,
            demandLevel: 1,
            marketSizeLevel: 2
        )

        blockPartySponsorship = Advertisement(
            id: AdvertisementID(rawValue: "block-party-sponsorship"),
            name: "Sponsor the Neighborhood Block Party",
            smallIcon: .system("party.popper.fill"),
            description: "Sponsor the neighborhood block party and introduce your business to the community.",
            paymentSchedule: .oneTime,
            demandLevel: 3,
            marketSizeLevel: 2
        )

        neighborhoodGazetteAdvertisement = Advertisement(
            id: AdvertisementID(rawValue: "neighborhood-gazette-advertisement"),
            name: "Neighborhood Gazette Ad",
            smallIcon: .system("newspaper.fill"),
            description: "Run a weekly advertisement in the Neighborhood Gazette.",
            paymentSchedule: .weekly,
            demandLevel: 2,
            marketSizeLevel: 3
        )

        townNewspaperAdvertisement = Advertisement(
            id: AdvertisementID(rawValue: "town-newspaper-advertisement"),
            name: "Town Newspaper Ad",
            smallIcon: .system("newspaper.fill"),
            description: "Run a weekly advertisement in the town newspaper.",
            paymentSchedule: .weekly,
            demandLevel: 3,
            marketSizeLevel: 3
        )

        socialMediaAdvertisement = Advertisement(
            id: AdvertisementID(rawValue: "social-media-advertisement"),
            name: "Social Media Ads",
            smallIcon: .system("megaphone.fill"),
            description: "Run targeted social media ads throughout the local community.",
            paymentSchedule: .weekly,
            demandLevel: 4,
            marketSizeLevel: 3
        )

        beachVolleyballSponsorship = Advertisement(
            id: AdvertisementID(rawValue: "beach-volleyball-sponsorship"),
            name: "Sponsor a Beach Volleyball Team",
            smallIcon: .system("volleyball.fill"),
            description: "Sponsor a local beach volleyball team to promote your smoothies.",
            paymentSchedule: .weekly,
            demandLevel: 4,
            marketSizeLevel: 5
        )

        youthBaseballSponsorship = Advertisement(
            id: AdvertisementID(rawValue: "youth-baseball-sponsorship"),
            name: "Sponsor a Youth Baseball Team",
            smallIcon: .system("baseball.fill"),
            description: "Sponsor a local youth baseball team to promote your hot dogs.",
            paymentSchedule: .weekly,
            demandLevel: 4,
            marketSizeLevel: 5
        )

        harvestEventSponsorship = Advertisement(
            id: AdvertisementID(rawValue: "harvest-event-sponsorship"),
            name: "Sponsor a Harvest Event",
            smallIcon: .system("basket.fill"),
            description: "Sponsor a local harvest event to promote your pies.",
            paymentSchedule: .weekly,
            demandLevel: 4,
            marketSizeLevel: 5
        )

        sportsPodcastPartnership = Advertisement(
            id: AdvertisementID(rawValue: "sports-podcast-partnership"),
            name: "Partner with a Sports Podcast",
            smallIcon: .system("mic.fill"),
            description: "Team up with a local sports podcast to promote your hot dogs.",
            paymentSchedule: .weekly,
            demandLevel: 5,
            marketSizeLevel: 4
        )

        fitnessInfluencerPartnership = Advertisement(
            id: AdvertisementID(rawValue: "fitness-influencer-partnership"),
            name: "Partner with a Fitness Influencer",
            smallIcon: .system("figure.run"),
            description: "Team up with a local health and fitness influencer to promote your smoothies.",
            paymentSchedule: .weekly,
            demandLevel: 5,
            marketSizeLevel: 4
        )

        gardeningPodcastPartnership = Advertisement(
            id: AdvertisementID(rawValue: "gardening-podcast-partnership"),
            name: "Partner with a Gardening Podcast",
            smallIcon: .system("leaf.circle.fill"),
            description: "Team up with a local gardening podcast to promote your pies.",
            paymentSchedule: .weekly,
            demandLevel: 5,
            marketSizeLevel: 4
        )

        billboardAdvertisement = Advertisement(
            id: AdvertisementID(rawValue: "billboard-advertisement"),
            name: "Billboard Advertising",
            smallIcon: .system("signpost.right.fill"),
            description: "Place billboards around town to keep your business visible.",
            paymentSchedule: .weekly,
            demandLevel: 4,
            marketSizeLevel: 4
        )

        radioAdvertisement = Advertisement(
            id: AdvertisementID(rawValue: "radio-advertisement"),
            name: "Radio Advertising",
            smallIcon: .system("radio.fill"),
            description: "Run recurring radio ads to reach customers throughout the local area.",
            paymentSchedule: .weekly,
            demandLevel: 5,
            marketSizeLevel: 5
        )

        tierZero = AdvertisementTier(
            id: AdvertisementTierID(rawValue: "tier-zero"),
            level: 0,
            advertisements: [noAdvertisement]
        )

        tierOne = AdvertisementTier(
            id: AdvertisementTierID(rawValue: "tier-one"),
            level: 1,
            advertisements: [
                canvassing,
                neighborhoodFlyers,
                clubhouseAdvertisement
            ]
        )

        tierTwo = AdvertisementTier(
            id: AdvertisementTierID(rawValue: "tier-two"),
            level: 2,
            advertisements: [
                blockPartySponsorship,
                neighborhoodGazetteAdvertisement
            ]
        )

        tierThree = AdvertisementTier(
            id: AdvertisementTierID(rawValue: "tier-three"),
            level: 3,
            advertisements: [
                townNewspaperAdvertisement,
                socialMediaAdvertisement
            ]
        )

        smoothieTierFour = AdvertisementTier(
            id: AdvertisementTierID(rawValue: "smoothie-tier-four"),
            level: 4,
            advertisements: [
                beachVolleyballSponsorship,
                fitnessInfluencerPartnership,
                billboardAdvertisement
            ]
        )

        hotDogTierFour = AdvertisementTier(
            id: AdvertisementTierID(rawValue: "hot-dog-tier-four"),
            level: 4,
            advertisements: [
                youthBaseballSponsorship,
                sportsPodcastPartnership,
                billboardAdvertisement
            ]
        )

        pieTierFour = AdvertisementTier(
            id: AdvertisementTierID(rawValue: "pie-tier-four"),
            level: 4,
            advertisements: [
                harvestEventSponsorship,
                gardeningPodcastPartnership,
                billboardAdvertisement
            ]
        )

        tierFive = AdvertisementTier(
            id: AdvertisementTierID(rawValue: "tier-five"),
            level: 5,
            advertisements: [radioAdvertisement]
        )
    }
}
