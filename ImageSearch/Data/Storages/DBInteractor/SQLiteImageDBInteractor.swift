//
//  SQLiteImageDBInteractor.swift
//  ImageSearch
//
//  Created by Denis Simon on 01/02/2024.
//

import Foundation

class SQLiteImageDBInteractor: ImageDBInteractor {
    
    let sqliteAdapter: SQLite?
    
    let imagesTable = "Images"
    let imagesColumns = SQLValues([
        (.INT, nil), // id
        (.TEXT, nil), // searchId
        (.INT, nil), // sortId
        (.TEXT, nil) // json
    ])
    
    init(with sqliteAdapter: SQLite?) {
        self.sqliteAdapter = sqliteAdapter
        createImageTable()
    }
    
    private func createImageTable() {
        guard let sqliteAdapter = sqliteAdapter else { return }
        let sqlStatement = """
            CREATE TABLE IF NOT EXISTS "\(imagesTable)"(
                "id" INTEGER NOT NULL,
                "searchId" CHAR(255) NOT NULL,
                "sortId" INT NOT NULL,
                "json" TEXT NOT NULL,
                PRIMARY KEY("id" AUTOINCREMENT)
            );
            """
        do {
            try sqliteAdapter.beginTransaction()
            try sqliteAdapter.createTable(sql: sqlStatement) // create table if not exists
            try sqliteAdapter.dropIndex(in: imagesTable, forColumn: "searchId") // drop index if exists
            try sqliteAdapter.addIndex(to: imagesTable, forColumn: "searchId")
            try sqliteAdapter.endTransaction()
        } catch {
            print("SQLite:", error.localizedDescription)
        }
    }
    
    func saveImage<T: Codable>(_ image: T, searchId: String, sortId: Int, type: T.Type, completion: @escaping (Bool?) -> Void) {
        guard let sqliteAdapter = sqliteAdapter else {
            completion(nil)
            return
        }
        let encoder = JSONEncoder()
        if let encodedData = try? encoder.encode(image) {
            if let jsonString = String(data: encodedData, encoding: .utf8) {
                do {
                    let _ = try sqliteAdapter.insertRow(sql: "INSERT INTO \(imagesTable) (searchId, sortId, json) VALUES (?, ?, ?);", params: [searchId, sortId, jsonString])
                    completion(true)
                } catch {
                    print("SQLite:", error.localizedDescription)
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        } else {
            completion(nil)
        }
    }
    
    func getImages<T: Codable>(searchId: String, type: T.Type, completion: @escaping ([T]?) -> Void) {
        guard let sqliteAdapter = sqliteAdapter else {
            completion(nil)
            return
        }
        
        do {
            let sql = "SELECT * FROM \(imagesTable) WHERE searchId = ? ORDER BY sortId ASC;"
            let results = try sqliteAdapter.getRow(sql: sql, params: [searchId], valuesToGet: imagesColumns)
            
            var images: [T] = []
            
            for row in results {
                let json = row[3] // 'json' column
                if let jsonData = (json.value as! String).data(using: .utf8) {
                    let decoder = JSONDecoder()
                    if let decoded = try? decoder.decode(type, from: jsonData) {
                        images.append(decoded)
                    } else {
                        completion(nil)
                    }
                } else {
                    completion(nil)
                }
            }
            completion(images)
        } catch {
            print("SQLite:", error.localizedDescription)
            completion(nil)
        }
    }
    
    /* Note: another way (albeit more computationally heavy) to perform this check is as follows:
     func checkImageCount(searchId: String, completion: @escaping (Int?) -> Void) {
        ...
        let sql = "SELECT COUNT(*) FROM \(imagesTable) WHERE searchId = ?;"
        let rowCount = try sqliteAdapter.getRowCountWithCondition(sql: sql, params: [searchId])
        completion(rowCount) // Returns 0 if images with the given searchId are not already cached
        ...
     }
     */
    func checkImagesAreCached(searchId: String, completion: @escaping (Bool?) -> Void) {
        guard let sqliteAdapter = sqliteAdapter else {
            completion(nil)
            return
        }
        let sql = "SELECT * FROM \(imagesTable) WHERE searchId = ? LIMIT 1"
        do {
            let rows = try sqliteAdapter.getRow(sql: sql, params: [searchId], valuesToGet: imagesColumns)
            completion(rows.count == 1 ? true : false)
        } catch {
            completion(nil)
        }
    }
    
    func deleteAllImages() {
        guard let sqliteAdapter = sqliteAdapter else { return }
        do {
            try sqliteAdapter.deleteAllRows(in: imagesTable)
        } catch {
            print("SQLite:", error.localizedDescription)
        }
    }
}
