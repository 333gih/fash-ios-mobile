import Foundation

final class AddressLocalStore {
    private let key = "fash_address_book_local"
    func loadJSON() -> Data? { UserDefaults.standard.data(forKey: key) }
    func saveJSON(_ data: Data) { UserDefaults.standard.set(data, forKey: key) }
}
