final class SQLTable: Sendable {
    
    let name: String
    let columns: SQLTableColums
    let primaryKey: String
    
    init(name: String, columns: SQLTableColums, primaryKey: String = "id") {
        self.name = name
        self.columns = columns
        self.primaryKey = primaryKey
    }
}
