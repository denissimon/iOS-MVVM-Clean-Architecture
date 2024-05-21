import Foundation

class SQLiteImageDBInteractor: ImageDBInteractor {
    
    let sqliteAdapter: SQLite?
    
    let imagesTable = SQLTable(
        name: "Images",
        columns: [
            ("id", .INT),
            ("searchId", .TEXT),
            ("sortId", .INT),
            ("json", .TEXT)
        ]
    )
    
    init(with sqliteAdapter: SQLite?) {
        self.sqliteAdapter = sqliteAdapter
        createImageTable()
    }
    
    private func createImageTable() {
        guard let sqliteAdapter = sqliteAdapter else { return }
        let sqlStatement = """
            CREATE TABLE IF NOT EXISTS "\(imagesTable.name)"(
                "\(imagesTable.primaryKey)" INTEGER NOT NULL,
                "searchId" CHAR(255) NOT NULL,
                "sortId" INT NOT NULL,
                "json" TEXT NOT NULL,
                PRIMARY KEY("\(imagesTable.primaryKey)" AUTOINCREMENT)
            );
            """
        do {
            try sqliteAdapter.createTable(sql: sqlStatement) // create table if not exists
            try sqliteAdapter.addIndex(to: imagesTable, forColumn: "searchId") // add index if not exists
        } catch {
            print("SQLite:", error)
        }
    }
    
    func saveImage<T: Codable>(_ image: T, searchId: String, sortId: Int, type: T.Type) async -> Bool? {
        guard let sqliteAdapter = sqliteAdapter else { return nil }
        
        let encoder = JSONEncoder()
        if let encodedData = try? encoder.encode(image) {
            if let jsonString = String(data: encodedData, encoding: .utf8) {
                do {
                    let sql = "INSERT INTO \(imagesTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
                    let _ = try sqliteAdapter.insertRow(sql: sql, params: [searchId, sortId, jsonString])
                    return true
                } catch {
                    print("SQLite:", error)
                    return nil
                }
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    func getImages<T: Codable>(searchId: String, type: T.Type) async -> [T]? {
        guard let sqliteAdapter = sqliteAdapter else { return nil }
        
        do {
            var images: [T] = []
            
            let sql = "SELECT * FROM \(imagesTable.name) WHERE searchId = ? ORDER BY sortId ASC;"
            guard let results = try sqliteAdapter.getRow(from: imagesTable, sql: sql, params: [searchId]) else {
                return nil
            }
            
            for row in results {
                let json = row[3] // 'json' column
                if let jsonData = (json.value as! String).data(using: .utf8) {
                    let decoder = JSONDecoder()
                    if let decoded = try? decoder.decode(type, from: jsonData) {
                        images.append(decoded)
                    } else {
                        return nil
                    }
                } else {
                    return nil
                }
            }
            return images
        } catch {
            print("SQLite:", error)
            return nil
        }
    }
    
    /* Another way (albeit more computationally heavy) to perform this check is as follows:
     func checkImagesAreCached(searchId: String) async -> Int? {
        ...
        let sql = "SELECT count(*) FROM \(imagesTable.name) WHERE searchId = ?;"
        let rowCount = try? sqliteAdapter.getRowCountWithCondition(sql: sql, params: [searchId])
        return rowCount // Returns 0 if images with the given searchId are not already cached
        ...
     }
     */
    func checkImagesAreCached(searchId: String) async -> Bool? {
        guard let sqliteAdapter = sqliteAdapter else { return nil }
        
        let sql = "SELECT * FROM \(imagesTable.name) WHERE searchId = ? LIMIT 1"
        do {
            if let _ = try sqliteAdapter.getRow(from: imagesTable, sql: sql, params: [searchId]) {
                return true
            }
            return false
        } catch {
            print("SQLite:", error)
            return nil
        }
    }
    
    func deleteAllImages() async {
        guard let sqliteAdapter = sqliteAdapter else { return }
        do {
            try sqliteAdapter.deleteAllRows(in: imagesTable)
        } catch {
            print("SQLite:", error)
        }
    }
}
