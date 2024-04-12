//
//  SQLTable.swift
//  ImageSearch
//
//  Created by Denis Simon on 04/11/2024.
//

class SQLTable {
    let name: String
    let columnTypes: SQLValues
    let primaryKey: String
    
    init(name: String, columnTypes: SQLValues, primaryKey: String = "id") {
        self.name = name
        self.columnTypes = columnTypes
        self.primaryKey = primaryKey
    }
}
