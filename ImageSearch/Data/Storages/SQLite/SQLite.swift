//
//  SQLite.swift
//  ImageSearch
//
//  Created by Denis Simon on 01/14/2024.
//

import Foundation
import SQLite3

enum SQLiteError: Error {
    case OpenDB(_ msg: String)
    case Prepare(_ msg: String)
    case Step(_ msg: String)
    case Bind(_ msg: String)
    case Column(_ msg: String)
    case Statement(_ msg: String)
    case Other(_ msg: String)
}

// http://www.sqlite.org/datatype3.html
enum SQLType {
    case INT // Includes INT, INTEGER, INT2, INT8, BIGINT, MEDIUMINT, SMALLINT, TINYINT
    case BOOL // Includes BOOL, BOOLEAN, BIT
    case TEXT // Includes TEXT, CHAR, CHARACTER, VARCHAR, CLOB, VARIANT, VARYING_CHARACTER, NATIONAL_VARYING_CHARACTER, NATIVE_CHARACTER, NCHAR, NVARCHAR
    case REAL // Includes REAL, NUMERIC, DECIMAL, FLOAT, DOUBLE, DOUBLE_PRECISION
    case BLOB // Includes BLOB, BINARY, VARBINARY
    case DATE // Includes DATE, DATETIME, TIME, TIMESTAMP
}

enum SQLOrder {
    case ASC
    case DESC
    case none
}

/// enum SQLType has the following cases:
/// case INT (includes INT, INTEGER, INT2, INT8, BIGINT, MEDIUMINT, SMALLINT, TINYINT, BIT)
/// case BOOL (includes BOOL, BOOLEAN
/// case TEXT (includes TEXT, CHAR, CHARACTER, VARCHAR, CLOB, VARIANT, VARYING_CHARACTER, NATIONAL_VARYING_CHARACTER, NATIVE_CHARACTER, NCHAR, NVARCHAR)
/// case REAL (includes REAL, NUMERIC, DECIMAL, FLOAT, DOUBLE, DOUBLE_PRECISION)
/// case BLOB (includes BLOB, BINARY, VARBINARY)
/// case DATE (includes DATE, DATETIME, TIME, TIMESTAMP)
typealias SQLValues = [(type: SQLType, value: Any?)]

protocol SQLiteType {
    func createTable(sql: String) throws
    func checkIfTableExists(_ table: SQLTable) throws -> Bool
    func dropTable(_ table: SQLTable, vacuum: Bool) throws
    func addIndex(to table: SQLTable, forColumn columnName: String, unique: Bool, order: SQLOrder) throws
    func checkIfIndexExists(in table: SQLTable, indexName: String) throws -> Bool
    func dropIndex(in table: SQLTable, forColumn columnName: String) throws
    func beginTransaction() throws
    func endTransaction() throws
    func insertRow(sql: String, params: [Any]?) throws -> Int
    func updateRow(sql: String, params: [Any]?) throws
    func deleteRow(sql: String, params: [Any]?) throws
    func deleteByID(in table: SQLTable, id: Int) throws
    func deleteAllRows(in table: SQLTable, vacuum: Bool, resetAutoincrement: Bool) throws
    func getRowCount(in table: SQLTable) throws -> Int
    func getRowCountWithCondition(sql: String, params: [Any]?) throws -> Int
    func getRow(from table: SQLTable, sql: String, params: [Any]?) throws -> [SQLValues]
    func getAllRows(from table: SQLTable) throws -> [SQLValues]
    func getByID(from table: SQLTable, id: Int) throws -> SQLValues
    func getLastRow(from table: SQLTable) throws -> SQLValues
    func getLastInsertID() -> Int
    func vacuum() throws
    func resetAutoincrement(in table: SQLTable) throws
    func query(sql: String, params: [Any]?) throws
}

class SQLite: SQLiteType {
    
    private(set) var dbPointer: OpaquePointer?
    private(set) var dbPath: String!
    
    private let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
    private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    
    var dateFormatter = DateFormatter()
    
    init(path: String, recreateDB: Bool = false) throws {
        if recreateDB {
            try deleteDB(path: path)
        }
        
        var db: OpaquePointer?
        
        if sqlite3_open(path, &db) == SQLITE_OK {
            dbPointer = db
            dbPath = path
            setUp()
            log("database opened successfully, path: \(path)")
        } else {
            defer {
                if db != nil {
                    sqlite3_close(db)
                }
            }
            dbPointer = nil
            throw SQLiteError.OpenDB(getErrorMessage(dbPointer: db))
        }
    }
    
    deinit {
        if dbPointer != nil {
            sqlite3_close(dbPointer)
            dbPointer = nil
        }
    }
    
    private func setUp() {
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    }
    
    private func deleteDB(path: String) throws {
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(atPath: path)
        } catch {
            throw SQLiteError.Other("SQLite file has not been deleted")
        }
    }
    
    private func log(_ str: String) {
        #if DEBUG
        print("SQLite: \(str)")
        #endif
    }
    
    private func getErrorMessage(dbPointer: OpaquePointer?) -> String {
        if let errorPointer = sqlite3_errmsg(dbPointer) {
            let errorMessage = String(cString: errorPointer)
            return errorMessage
        }
        return "SQLite error"
    }
    
    private func prepareStatement(sql: String) throws -> OpaquePointer? {
        var queryStatement: OpaquePointer?
        guard sqlite3_prepare_v2(dbPointer, sql, -1, &queryStatement, nil) == SQLITE_OK else {
            throw SQLiteError.Prepare(getErrorMessage(dbPointer: dbPointer))
        }
        return queryStatement
    }
    
    private func bindPlaceholders(sqlStatement: OpaquePointer?, params: [Any]?) throws {
        guard let params = params else { return }
        
        let paramsCount = sqlite3_bind_parameter_count(sqlStatement)
        let count = params.count
        if paramsCount != Int32(count) {
            throw SQLiteError.Bind(getErrorMessage(dbPointer: dbPointer))
        }
        
        for index in 0...(count-1) {
            
            let index = index+1 // placeholder serial number, should start with 1
            
            var statusCode: Int32 = 0
            
            // Detect placeholder data types
            if let intValue = params[index - 1] as? Int {
                statusCode = sqlite3_bind_int(sqlStatement, Int32(index), Int32(intValue))
            } else if let boolValue = params[index - 1] as? Bool {
                statusCode = sqlite3_bind_int(sqlStatement, Int32(index), Int32(boolValue ? 1 : 0 ))
            } else if let stringValue = params[index - 1] as? NSString {
                statusCode = sqlite3_bind_text(sqlStatement, Int32(index), stringValue.utf8String, -1, SQLITE_TRANSIENT)
            } else if let doubleValue = params[index - 1] as? Double {
                statusCode = sqlite3_bind_double(sqlStatement, Int32(index), doubleValue)
            } else if let data = params[index - 1] as? Data {
                data.withUnsafeBytes { bytes in
                    statusCode = sqlite3_bind_blob(sqlStatement, Int32(index), bytes.baseAddress, Int32(data.count), SQLITE_TRANSIENT)
                }
            } else if let date = params[index - 1] as? Date {
                let dateStr = dateFormatter.string(from: date)
                statusCode = sqlite3_bind_text(sqlStatement, Int32(index), dateStr, -1, SQLITE_TRANSIENT)
            } else {
                statusCode = sqlite3_bind_null(sqlStatement, Int32(index))
            }
            
            guard statusCode == SQLITE_OK else {
                throw SQLiteError.Bind(getErrorMessage(dbPointer: dbPointer))
            }
        }
    }
    
    private func operation(sql: String, params: [Any]? = nil) throws {
        let sqlStatement = try prepareStatement(sql: sql)
        defer {
            sqlite3_finalize(sqlStatement)
        }
        
        try bindPlaceholders(sqlStatement: sqlStatement, params: params)
        
        guard sqlite3_step(sqlStatement) == SQLITE_DONE else {
            throw SQLiteError.Step(getErrorMessage(dbPointer: dbPointer))
        }
    }
    
    func createTable(sql: String) throws {
        guard sql.uppercased().trimmingCharacters(in: .whitespaces).hasPrefix("CREATE ") else {
            throw SQLiteError.Statement("Invalid SQL statement")
        }
        try operation(sql: sql)
        log("successfully created table, sql: \(sql)")
    }
    
    func checkIfTableExists(_ table: SQLTable) throws -> Bool {
        if let count = try? getRowCountWithCondition(sql: "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='\(table.name)';") {
            let result = count == 1 ? true : false
            log("successfully checked if table \(table.name) exists: \(result)")
            return result
        }
        throw SQLiteError.Other(getErrorMessage(dbPointer: dbPointer))
    }
    
    func dropTable(_ table: SQLTable, vacuum: Bool = true) throws {
        let sql = "DROP TABLE IF EXISTS \(table.name);"
        try operation(sql: sql)
        if vacuum {
            try self.vacuum()
        }
        log("successfully droped table \(table.name)")
    }
    
    func addIndex(to table: SQLTable, forColumn columnName: String, unique: Bool = false, order: SQLOrder = .none) throws {
        
        let indexName = "\(table.name)_\(columnName)_idx"
        
        var sql = ""
        if !unique {
            sql = "CREATE INDEX \"\(indexName)\" ON \"\(table.name)\" (\"\(columnName)\""
        } else {
            sql = "CREATE UNIQUE INDEX \"\(indexName))\" ON \"\(table.name)\" (\"\(columnName)\""
        }
        
        switch order {
        case .ASC:
            sql += " ASC);"
        case .DESC:
            sql += " DESC);"
        case .none:
            sql += ");"
        }
        
        try operation(sql: sql)
        log("successfully added index \(indexName)")
    }
    
    func checkIfIndexExists(in table: SQLTable, indexName: String) throws -> Bool {
        if let count = try? getRowCountWithCondition(sql: "SELECT count(*) FROM sqlite_master WHERE type='index' AND tbl_name='\(table.name)' AND name='\(indexName)';") {
            let result = count == 1 ? true : false
            log("successfully checked if index \(indexName) exists: \(result)")
            return result
        }
        throw SQLiteError.Other(getErrorMessage(dbPointer: dbPointer))
    }
    
    func dropIndex(in table: SQLTable, forColumn columnName: String) throws {
        let indexName = "\(table.name)_\(columnName)_idx"
        let sql = "DROP INDEX IF EXISTS \"\(indexName)\";"
        try operation(sql: sql)
        log("successfully droped index \(indexName)")
    }
    
    func beginTransaction() throws {
        let sql = "BEGIN TRANSACTION;"
        try operation(sql: sql)
        log("BEGIN TRANSACTION")
    }
    
    func endTransaction() throws {
        let sql = "COMMIT;"
        try operation(sql: sql)
        log("COMMIT")
    }
    
    /// Can be used to insert one or several rows depending on the SQL statement
    /// - Returns: The id for the last inserted row
    func insertRow(sql: String, params: [Any]? = nil) throws -> Int {
        guard sql.uppercased().trimmingCharacters(in: .whitespaces).hasPrefix("INSERT ") else {
            throw SQLiteError.Statement("Invalid SQL statement")
        }
        try operation(sql: sql, params: params)
        log("successfully inserted row(s), sql: \(sql)")
        return getLastInsertID()
    }
    
    /// Can be used to update one or several rows depending on the SQL statement
    func updateRow(sql: String, params: [Any]? = nil) throws {
        guard sql.uppercased().trimmingCharacters(in: .whitespaces).hasPrefix("UPDATE ") else {
            throw SQLiteError.Statement("Invalid SQL statement")
        }
        try operation(sql: sql, params: params)
        log("successfully updated row(s), sql: \(sql)")
    }
    
    /// Can be used to delete one or several rows depending on the SQL statement
    func deleteRow(sql: String, params: [Any]? = nil) throws {
        guard sql.uppercased().trimmingCharacters(in: .whitespaces).hasPrefix("DELETE ") else {
            throw SQLiteError.Statement("Invalid SQL statement")
        }
        try operation(sql: sql, params: params)
        log("successfully deleted row(s), sql: \(sql)")
    }
    
    func deleteByID(in table: SQLTable, id: Int) throws {
        let sql = "DELETE FROM \(table.name) WHERE \(table.primaryKey) = ?;"
        try operation(sql: sql, params: [id])
        log("successfully deleted a row by id \(id) in \(table.name)")
    }
    
    func deleteAllRows(in table: SQLTable, vacuum: Bool = true, resetAutoincrement: Bool = true) throws {
        let sql = "DELETE FROM \(table.name);"
        try operation(sql: sql)
        log("successfully deleted all rows in \(table.name)")
        if vacuum {
            try self.vacuum()
        }
        if resetAutoincrement {
            try self.resetAutoincrement(in: table)
        }
    }
    
    func getRowCount(in table: SQLTable) throws -> Int {
        let sql = "SELECT count(*) FROM \(table.name);"
        let sqlStatement = try prepareStatement(sql: sql)
        defer {
            sqlite3_finalize(sqlStatement)
        }
        guard sqlite3_step(sqlStatement) == SQLITE_ROW else {
            throw SQLiteError.Step(getErrorMessage(dbPointer: dbPointer))
        }
        let count = sqlite3_column_int(sqlStatement, 0)
        log("successfully got a row count in \(table.name): \(count)")
        return Int(count)
    }
    
    func getRowCountWithCondition(sql: String, params: [Any]? = nil) throws -> Int {
        guard sql.uppercased().trimmingCharacters(in: .whitespaces).hasPrefix("SELECT ") else {
            throw SQLiteError.Statement("Invalid SQL statement")
        }
        
        let sqlStatement = try prepareStatement(sql: sql)
        defer {
            sqlite3_finalize(sqlStatement)
        }
        
        try bindPlaceholders(sqlStatement: sqlStatement, params: params)
        
        guard sqlite3_step(sqlStatement) == SQLITE_ROW else {
            throw SQLiteError.Step(getErrorMessage(dbPointer: dbPointer))
        }
        let count = sqlite3_column_int(sqlStatement, 0)
        log("successfully got a row count with condition: \(count), sql: \(sql)")
        return Int(count)
    }
    
    /// Can be used to read one or several rows depending on the SQL statement
    func getRow(from table: SQLTable, sql: String, params: [Any]? = nil) throws -> [SQLValues] {
        guard sql.uppercased().trimmingCharacters(in: .whitespaces).hasPrefix("SELECT ") else {
            throw SQLiteError.Statement("Invalid SQL statement")
        }
        
        let sqlStatement = try prepareStatement(sql: sql)
        defer {
            sqlite3_finalize(sqlStatement)
        }
        
        try bindPlaceholders(sqlStatement: sqlStatement, params: params)
        
        var allRows: [SQLValues] = []
        var rowValues: SQLValues = SQLValues([])
        
        while sqlite3_step(sqlStatement) == SQLITE_ROW {
            rowValues = SQLValues([])
            for (index,value) in table.columnTypes.enumerated() {
                
                let index = Int32(index) // column serial number, should start with 0
                
                // Check for data types of returned values
                switch value.type {
                case .INT:
                    let intValue = sqlite3_column_int64(sqlStatement, index)
                    rowValues.append((value.type, Int(intValue)))
                case .BOOL:
                    let intValue = sqlite3_column_int(sqlStatement, index)
                    rowValues.append((value.type, intValue == 1 ? true : false))
                case .TEXT:
                    if let queryResult = sqlite3_column_text(sqlStatement, index) {
                        let stringValue = String(cString: queryResult)
                        rowValues.append((value.type, stringValue))
                    } else {
                        rowValues.append((value.type, nil))
                    }
                case .REAL:
                    let doubleValue = sqlite3_column_double(sqlStatement, index)
                    rowValues.append((value.type, doubleValue))
                case .BLOB:
                    if let queryResult = sqlite3_column_blob(sqlStatement, index) {
                        let count = sqlite3_column_bytes(sqlStatement, index)
                        let dataValue = Data(bytes: queryResult, count: Int(count))
                        rowValues.append((value.type, dataValue))
                    } else {
                        rowValues.append((value.type, nil))
                    }
                case .DATE:
                    // If it's in date format
                    if let queryResult = sqlite3_column_text(sqlStatement, index) {
                        var dateStrValue = String(cString: queryResult)
                        if dateStrValue.count == 10 {
                            dateStrValue += " 00:00:00"
                        }
                        if let dateValue = dateFormatter.date(from: dateStrValue) {
                            rowValues.append((value.type, dateValue))
                            continue
                        }
                    }
                    // If it's in time interval format
                    let timeInterval = sqlite3_column_double(sqlStatement, index)
                    let dateValue = Date(timeIntervalSince1970: timeInterval)
                    rowValues.append((value.type, dateValue))
                }
            }
            allRows.append(rowValues)
        }
        
        log("successfully read row(s), count: \(allRows.count), sql: \(sql)")
        return allRows
    }
    
    func getAllRows(from table: SQLTable) throws -> [SQLValues] {
        let sql = "SELECT * FROM \(table.name);"
        let result = try getRow(from: table, sql: sql)
        log("successfully read all rows in \(table.name), count: \(result.count)")
        return result
    }
    
    func getByID(from table: SQLTable, id: Int) throws -> SQLValues {
        let sql = "SELECT * FROM \(table.name) WHERE \(table.primaryKey) = ? LIMIT 1;"
        let result = try getRow(from: table, sql: sql, params: [id])
        if result.count == 1 {
            log("successfully read a row by id \(id) in \(table.name)")
            return result[0]
        } else {
            throw SQLiteError.Column(getErrorMessage(dbPointer: dbPointer))
        }
    }
    
    func getLastRow(from table: SQLTable) throws -> SQLValues {
        let sql = "SELECT * FROM \(table.name) WHERE \(table.primaryKey) = (SELECT MAX(\(table.primaryKey)) FROM \(table.name));"
        let result = try getRow(from: table, sql: sql)
        if result.count == 1 {
            log("successfully read last row in \(table.name)")
            return result[0]
        } else {
            throw SQLiteError.Column(getErrorMessage(dbPointer: dbPointer))
        }
    }
    
    func getLastInsertID() -> Int {
        return Int(sqlite3_last_insert_rowid(dbPointer))
    }
    
    /// Repack the DB to take advantage of deleted data
    func vacuum() throws {
        let sql = "VACUUM;"
        try operation(sql: sql)
        log("VACUUM")
    }
    
    func resetAutoincrement(in table: SQLTable) throws {
        let sql = "UPDATE sqlite_sequence SET SEQ=0 WHERE name='\(table.name)';"
        try operation(sql: sql)
        log("successfully reseted autoincrement in \(table.name)")
    }
    
    /// Any other query except reading
    func query(sql: String, params: [Any]? = nil) throws {
        try operation(sql: sql, params: params)
        log("successful query, sql: \(sql)")
    }
}
