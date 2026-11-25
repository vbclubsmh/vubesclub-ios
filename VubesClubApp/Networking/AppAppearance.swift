import Foundation

struct AppAppearance: Decodable {
    struct Media: Decodable {
        let url: String
    }

    let welcomeCover: Media
    let mapArtwork: Media
    let wordmark: Media
    let reviewCover: Media?
}
