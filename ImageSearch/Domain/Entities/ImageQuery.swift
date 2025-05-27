import Foundation

struct ImageQuery: Equatable {
    let query: String
    
    init?(query: String) {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        self.query = query
    }
}
