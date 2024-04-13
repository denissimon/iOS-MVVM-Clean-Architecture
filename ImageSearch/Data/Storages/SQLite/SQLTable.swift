//
//  SQLTable.swift
//  ImageSearch
//
//  Created by Denis Simon on 04/11/2024.
//

class SQLTable {
    
    let name: String
    let columns: SQLTableColums
    let primaryKey: String
    
    init(name: String, columns: SQLTableColums, primaryKey: String = "id") {
        self.name = name
        self.columns = columns
        self.primaryKey = primaryKey
    }
}
