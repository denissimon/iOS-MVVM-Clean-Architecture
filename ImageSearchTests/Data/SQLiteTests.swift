//
//  SQLiteTests.swift
//  ImageSearchTests
//
//  Created by Denis Simon on 03/31/2024.
//

import XCTest
@testable import ImageSearch

class SQLiteTests: XCTestCase {
    
    static let testDBPath = try! (FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("testDB.sqlite")).path
    static let testTable = SQLTable(
        name: "TestTable",
        columnTypes: SQLValues([
            (.INT, nil), // id
            (.TEXT, nil), // searchId
            (.INT, nil), // sortId
            (.TEXT, nil) // json
        ])
    )
    static let sqlite = try? SQLite(path: SQLiteTests.testDBPath)
    static let sqlStatementCreateTable = """
        CREATE TABLE IF NOT EXISTS "\(SQLiteTests.testTable.name)"(
            "id" INTEGER NOT NULL,
            "searchId" CHAR(255) NOT NULL,
            "sortId" INT NOT NULL,
            "json" TEXT NOT NULL,
            PRIMARY KEY("id" AUTOINCREMENT)
        );
        """
    
    override func tearDown() {
        super.tearDown()
        try? SQLiteTests.sqlite?.deleteAllRows(in: SQLiteTests.testTable)
    }
    
    func testCreateTable() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlStatementCreateTable)
        let checkIfTableExists = try? SQLiteTests.sqlite?.checkIfTableExists(SQLiteTests.testTable)
        XCTAssertNotNil(checkIfTableExists)
        XCTAssertTrue(checkIfTableExists!)
    }
    
    func testCreateTable_whenInvalidTableName() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlStatementCreateTable)
        let someTable = SQLTable(name: "SomeTable", columnTypes: SQLValues())
        let checkIfTableExists = try? SQLiteTests.sqlite?.checkIfTableExists(someTable)
        XCTAssertNotNil(checkIfTableExists)
        XCTAssertFalse(checkIfTableExists!)
    }
    
    func testDropTable() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlStatementCreateTable)
        try? SQLiteTests.sqlite?.dropTable(SQLiteTests.testTable)
        let checkIfTableExists = try? SQLiteTests.sqlite?.checkIfTableExists(SQLiteTests.testTable)
        XCTAssertNotNil(checkIfTableExists)
        XCTAssertFalse(checkIfTableExists!)
    }
    
    func testDeleteAllRows() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlStatementCreateTable)
        
        let sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString"])
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString"])
        
        var rowCount = try? SQLiteTests.sqlite?.getRowCount(in: SQLiteTests.testTable)
        XCTAssertNotNil(rowCount)
        XCTAssertEqual(rowCount!, 2)
        
        try? SQLiteTests.sqlite?.deleteAllRows(in: SQLiteTests.testTable)
        
        rowCount = try? SQLiteTests.sqlite?.getRowCount(in: SQLiteTests.testTable)
        XCTAssertNotNil(rowCount)
        XCTAssertEqual(rowCount!, 0)
    }
    
    func testIndexesAndTransactions() {
        let columnName = "searchId"
        try? SQLiteTests.sqlite?.beginTransaction()
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlStatementCreateTable)
        try? SQLiteTests.sqlite?.addIndex(to: SQLiteTests.testTable, forColumn: columnName)
        try? SQLiteTests.sqlite?.endTransaction()
        
        let indexName = "\(SQLiteTests.testTable.name)_\(columnName)_idx"
        
        var checkIfIndexExists = try? SQLiteTests.sqlite?.checkIfIndexExists(in: SQLiteTests.testTable, indexName: indexName)
        XCTAssertNotNil(checkIfIndexExists)
        XCTAssertTrue(checkIfIndexExists!)
        
        try? SQLiteTests.sqlite?.dropIndex(in: SQLiteTests.testTable, forColumn: columnName)
        
        checkIfIndexExists = try? SQLiteTests.sqlite?.checkIfIndexExists(in: SQLiteTests.testTable, indexName: indexName)
        XCTAssertNotNil(checkIfIndexExists)
        XCTAssertFalse(checkIfIndexExists!)
    }
    
    func testIndexesAndTransactions_whenInvalidIndexName() {
        try? SQLiteTests.sqlite?.beginTransaction()
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlStatementCreateTable)
        try? SQLiteTests.sqlite?.addIndex(to: SQLiteTests.testTable, forColumn: "searchId")
        try? SQLiteTests.sqlite?.endTransaction()
        
        let checkIfIndexExists = try? SQLiteTests.sqlite?.checkIfIndexExists(in: SQLiteTests.testTable, indexName: "some_index")
        XCTAssertNotNil(checkIfIndexExists)
        XCTAssertFalse(checkIfIndexExists!)
    }
    
    func testInsertRow() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlStatementCreateTable)
        
        var rowCount = try? SQLiteTests.sqlite?.getRowCount(in: SQLiteTests.testTable)
        XCTAssertNotNil(rowCount)
        XCTAssertEqual(rowCount!, 0)
        
        let sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 5, "jsonString"])
        
        rowCount = try? SQLiteTests.sqlite?.getRowCount(in: SQLiteTests.testTable)
        XCTAssertNotNil(rowCount)
        XCTAssertEqual(rowCount!, 1)
        
        let row = try? SQLiteTests.sqlite?.getByID(from: SQLiteTests.testTable, id: 1)
        XCTAssertNotNil(row)
        XCTAssertEqual(row!.count, 4)
        XCTAssertEqual(Int(row![0].value as! Int32), 1)
        XCTAssertEqual(row![1].value as! String, "searchId")
        XCTAssertEqual(Int(row![2].value as! Int32), 5)
        XCTAssertEqual(row![3].value as! String, "jsonString")
    }
    
    func testInsertRow_whenInvalidSqlStatement() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlStatementCreateTable)
        
        let sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json, other) VALUES (?, ?, ?, ?);"
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 5, "jsonString", ""])
        
        let rowCount = try? SQLiteTests.sqlite?.getRowCount(in: SQLiteTests.testTable)
        XCTAssertNotNil(rowCount)
        XCTAssertEqual(rowCount!, 0)
    }
    
    func testUpdateRow() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlStatementCreateTable)
        
        var sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 5, "jsonString"])
        
        sqlStatement = "UPDATE \(SQLiteTests.testTable.name) SET searchId = ?, sortId = ?, json = ? WHERE id = ?"
        try? SQLiteTests.sqlite?.updateRow(sql: sqlStatement, params: ["searchId_1", 7, "jsonString_1", 1])
        
        let row = try? SQLiteTests.sqlite?.getByID(from: SQLiteTests.testTable, id: 1)
        XCTAssertNotNil(row)
        XCTAssertEqual(row!.count, 4)
        XCTAssertEqual(Int(row![0].value as! Int32), 1)
        XCTAssertEqual(row![1].value as! String, "searchId_1")
        XCTAssertEqual(Int(row![2].value as! Int32), 7)
        XCTAssertEqual(row![3].value as! String, "jsonString_1")
    }
    
    func testUpdateRow_whenInvalidId() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlStatementCreateTable)
        
        var sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 5, "jsonString"])
        
        sqlStatement = "UPDATE \(SQLiteTests.testTable.name) SET searchId = ?, sortId = ?, json = ? WHERE id = ?"
        try? SQLiteTests.sqlite?.updateRow(sql: sqlStatement, params: ["searchId_1", 7, "jsonString_1", 2])
        
        let row = try? SQLiteTests.sqlite?.getByID(from: SQLiteTests.testTable, id: 1)
        XCTAssertNotNil(row)
        XCTAssertEqual(row!.count, 4)
        XCTAssertEqual(Int(row![0].value as! Int32), 1)
        XCTAssertEqual(row![1].value as! String, "searchId")
        XCTAssertEqual(Int(row![2].value as! Int32), 5)
        XCTAssertEqual(row![3].value as! String, "jsonString")
    }
    
    func testDeleteRow() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlStatementCreateTable)
        
        var sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString"])
                
        sqlStatement = "DELETE FROM \(SQLiteTests.testTable.name) WHERE searchId = ?;"
        try? SQLiteTests.sqlite?.deleteRow(sql: sqlStatement, params: ["searchId"])
        
        let rowCount = try? SQLiteTests.sqlite?.getRowCount(in: SQLiteTests.testTable)
        XCTAssertNotNil(rowCount)
        XCTAssertEqual(rowCount!, 0)
    }
    
    func testDeleteRow_whenInvalidSqlStatement() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlStatementCreateTable)
        
        var sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString"])
                
        sqlStatement = "DELETE FROM \(SQLiteTests.testTable.name) WHERE someColumn = ?;"
        try? SQLiteTests.sqlite?.deleteRow(sql: sqlStatement, params: ["searchId"])
        
        let rowCount = try? SQLiteTests.sqlite?.getRowCount(in: SQLiteTests.testTable)
        XCTAssertNotNil(rowCount)
        XCTAssertEqual(rowCount!, 1)
    }
    
    func testDeleteByID() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlStatementCreateTable)
        
        let sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString"])
        
        try? SQLiteTests.sqlite?.deleteByID(in: SQLiteTests.testTable, id: 1)
        
        let rowCount = try? SQLiteTests.sqlite?.getRowCount(in: SQLiteTests.testTable)
        XCTAssertNotNil(rowCount)
        XCTAssertEqual(rowCount!, 0)
    }
    
    func testDeleteByID_whenInvalidId() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlStatementCreateTable)
        
        let sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString"])
        
        try? SQLiteTests.sqlite?.deleteByID(in: SQLiteTests.testTable, id: 2)
        
        let rowCount = try? SQLiteTests.sqlite?.getRowCount(in: SQLiteTests.testTable)
        XCTAssertNotNil(rowCount)
        XCTAssertEqual(rowCount!, 1)
    }
    
    func testGetRowCount() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlStatementCreateTable)
        
        let sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString"])
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString"])
        
        let rowCount = try? SQLiteTests.sqlite?.getRowCount(in: SQLiteTests.testTable)
        XCTAssertNotNil(rowCount)
        XCTAssertEqual(rowCount!, 2)
    }
    
    func testGetRowCountWithCondition() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlStatementCreateTable)
        
        var sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString"])
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId_1", 1, "jsonString_1"])
        
        var rowCount = try? SQLiteTests.sqlite?.getRowCount(in: SQLiteTests.testTable)
        XCTAssertNotNil(rowCount)
        XCTAssertEqual(rowCount!, 2)
        
        sqlStatement = "SELECT COUNT(*) FROM \(SQLiteTests.testTable.name) WHERE searchId = ?;"
        rowCount = try? SQLiteTests.sqlite?.getRowCountWithCondition(sql: sqlStatement, params: ["searchId_1"])
        XCTAssertNotNil(rowCount)
        XCTAssertEqual(rowCount!, 1)
    }
    
    func testGetRowCountWithCondition_whenInvalidCondition() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlStatementCreateTable)
        
        var sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString"])
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId_1", 2, "jsonString_1"])
        
        var rowCount = try? SQLiteTests.sqlite?.getRowCount(in: SQLiteTests.testTable)
        XCTAssertNotNil(rowCount)
        XCTAssertEqual(rowCount!, 2)
        
        sqlStatement = "SELECT COUNT(*) FROM \(SQLiteTests.testTable.name) WHERE searchId = ?;"
        rowCount = try? SQLiteTests.sqlite?.getRowCountWithCondition(sql: sqlStatement, params: ["searchId_2"])
        XCTAssertNotNil(rowCount)
        XCTAssertEqual(rowCount!, 0)
    }
    
    func testGetRow_whenOrderIsASC() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlStatementCreateTable)
        
        var sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString_1"])
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 2, "jsonString_2"])
        
        sqlStatement = "SELECT * FROM \(SQLiteTests.testTable.name) WHERE searchId = ? ORDER BY sortId ASC;"
        
        let rows = try? SQLiteTests.sqlite?.getRow(from: SQLiteTests.testTable, sql: sqlStatement, params: ["searchId"])
        XCTAssertNotNil(rows)
        XCTAssertEqual(rows!.count, 2)
        
        let firstRow = rows![0]
        XCTAssertEqual(firstRow.count, 4)
        XCTAssertEqual(Int(firstRow[0].value as! Int32), 1)
        XCTAssertEqual(firstRow[1].value as! String, "searchId")
        XCTAssertEqual(Int(firstRow[2].value as! Int32), 1)
        XCTAssertEqual(firstRow[3].value as! String, "jsonString_1")
    }
    
    func testGetRow_whenOrderIsDESC() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlStatementCreateTable)
        
        var sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString_1"])
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 2, "jsonString_2"])
        
        sqlStatement = "SELECT * FROM \(SQLiteTests.testTable.name) WHERE searchId = ? ORDER BY sortId DESC;"
        
        let rows = try? SQLiteTests.sqlite?.getRow(from: SQLiteTests.testTable, sql: sqlStatement, params: ["searchId"])
        XCTAssertNotNil(rows)
        XCTAssertEqual(rows!.count, 2)
        
        let firstRow = rows![0]
        XCTAssertEqual(firstRow.count, 4)
        XCTAssertEqual(Int(firstRow[0].value as! Int32), 2)
        XCTAssertEqual(firstRow[1].value as! String, "searchId")
        XCTAssertEqual(Int(firstRow[2].value as! Int32), 2)
        XCTAssertEqual(firstRow[3].value as! String, "jsonString_2")
    }
    
    func testGetRow_whenInvalidCondition() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlStatementCreateTable)
        
        var sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString_1"])
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 2, "jsonString_2"])
        
        sqlStatement = "SELECT * FROM \(SQLiteTests.testTable.name) WHERE searchId = ?;"
        let rows = try? SQLiteTests.sqlite?.getRow(from: SQLiteTests.testTable, sql: sqlStatement, params: ["someId"])
        XCTAssertNotNil(rows)
        XCTAssertEqual(rows!.count, 0)
    }
    
    func testGetAllRows() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlStatementCreateTable)
        
        let sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString_1"])
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 2, "jsonString_2"])
        
        let rows = try? SQLiteTests.sqlite?.getAllRows(from: SQLiteTests.testTable)
        XCTAssertNotNil(rows)
        XCTAssertEqual(rows!.count, 2)
        
        let firstRow = rows![0]
        XCTAssertEqual(firstRow.count, 4)
        XCTAssertEqual(Int(firstRow[0].value as! Int32), 1)
        XCTAssertEqual(firstRow[1].value as! String, "searchId")
        XCTAssertEqual(Int(firstRow[2].value as! Int32), 1)
        XCTAssertEqual(firstRow[3].value as! String, "jsonString_1")
        
        let secondRow = rows![1]
        XCTAssertEqual(secondRow.count, 4)
        XCTAssertEqual(Int(secondRow[0].value as! Int32), 2)
        XCTAssertEqual(secondRow[1].value as! String, "searchId")
        XCTAssertEqual(Int(secondRow[2].value as! Int32), 2)
        XCTAssertEqual(secondRow[3].value as! String, "jsonString_2")
    }
    
    func testGetByID() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlStatementCreateTable)
        
        let sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString_1"])
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 2, "jsonString_2"])
        
        var row = try? SQLiteTests.sqlite?.getByID(from: SQLiteTests.testTable, id: 1)
        XCTAssertNotNil(row)
        XCTAssertEqual(row!.count, 4)
        XCTAssertEqual(Int(row![0].value as! Int32), 1)
        XCTAssertEqual(row![1].value as! String, "searchId")
        XCTAssertEqual(Int(row![2].value as! Int32), 1)
        XCTAssertEqual(row![3].value as! String, "jsonString_1")
        
        row = try? SQLiteTests.sqlite?.getByID(from: SQLiteTests.testTable, id: 2)
        XCTAssertNotNil(row)
        XCTAssertEqual(row!.count, 4)
        XCTAssertEqual(Int(row![0].value as! Int32), 2)
        XCTAssertEqual(row![1].value as! String, "searchId")
        XCTAssertEqual(Int(row![2].value as! Int32), 2)
        XCTAssertEqual(row![3].value as! String, "jsonString_2")
    }
    
    func testGetByID_whenInvalidId() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlStatementCreateTable)
        
        let sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString_1"])
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 2, "jsonString_2"])
        
        let row = try? SQLiteTests.sqlite?.getByID(from: SQLiteTests.testTable, id: 3)
        XCTAssertNil(row)
    }
    
    func testGetLastRow() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlStatementCreateTable)
        
        let sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString_1"])
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 2, "jsonString_2"])
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 3, "jsonString_3"])
        
        let rowCount = try? SQLiteTests.sqlite?.getRowCount(in: SQLiteTests.testTable)
        XCTAssertNotNil(rowCount)
        XCTAssertEqual(rowCount!, 3)
        
        let row = try? SQLiteTests.sqlite?.getLastRow(from: SQLiteTests.testTable)
        XCTAssertNotNil(row)
        XCTAssertEqual(row!.count, 4)
        XCTAssertEqual(Int(row![0].value as! Int32), 3)
        XCTAssertEqual(row![1].value as! String, "searchId")
        XCTAssertEqual(Int(row![2].value as! Int32), 3)
        XCTAssertEqual(row![3].value as! String, "jsonString_3")
    }
    
    func testGetLastInsertId() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlStatementCreateTable)
        
        let sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString"])
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString"])
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString"])
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString"])
        let returnedLastId = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString"])
        
        let lastInsertId = SQLiteTests.sqlite?.getLastInsertID()
        XCTAssertNotNil(lastInsertId)
        XCTAssertEqual(lastInsertId!, 5)
        XCTAssertEqual(returnedLastId, lastInsertId!)
    }
    
    func testResetAutoincrement() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlStatementCreateTable)
        
        let sqlStatementInsert = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatementInsert, params: ["searchId", 1, "jsonString"])
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatementInsert, params: ["searchId", 1, "jsonString"])
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatementInsert, params: ["searchId", 1, "jsonString"])
        
        let sqlStatementSelect = "SELECT SEQ from sqlite_sequence WHERE name='\(SQLiteTests.testTable.name)'"
        var seq = try? SQLiteTests.sqlite?.getRowCountWithCondition(sql: sqlStatementSelect)
        XCTAssertNotNil(seq)
        XCTAssertEqual(seq!, 3)
        var lastInsertId = SQLiteTests.sqlite?.getLastInsertID()
        XCTAssertNotNil(lastInsertId)
        XCTAssertEqual(lastInsertId!, 3)
        
        try? SQLiteTests.sqlite?.deleteAllRows(in: SQLiteTests.testTable, resetAutoincrement: true)
        
        seq = try? SQLiteTests.sqlite?.getRowCountWithCondition(sql: sqlStatementSelect)
        XCTAssertNotNil(seq)
        XCTAssertEqual(seq!, 0)
        
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatementInsert, params: ["searchId", 1, "jsonString"])
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatementInsert, params: ["searchId", 1, "jsonString"])
        
        seq = try? SQLiteTests.sqlite?.getRowCountWithCondition(sql: sqlStatementSelect)
        XCTAssertNotNil(seq)
        XCTAssertEqual(seq!, 2)
        lastInsertId = SQLiteTests.sqlite?.getLastInsertID()
        XCTAssertNotNil(lastInsertId)
        XCTAssertEqual(lastInsertId!, 2)
    }
    
    func testQuery() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlStatementCreateTable)
        
        let sqlStatementInsert = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatementInsert, params: ["searchId", 1, "jsonString"])
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatementInsert, params: ["searchId", 1, "jsonString"])
        
        let sqlStatementSelect = "SELECT SEQ FROM sqlite_sequence WHERE name='\(SQLiteTests.testTable.name)'"
        var seq = try? SQLiteTests.sqlite?.getRowCountWithCondition(sql: sqlStatementSelect)
        XCTAssertNotNil(seq)
        XCTAssertEqual(seq!, 2)
        var lastInsertId = SQLiteTests.sqlite?.getLastInsertID()
        XCTAssertNotNil(lastInsertId)
        XCTAssertEqual(lastInsertId!, 2)
        
        let sqlStatementUpdate = "UPDATE sqlite_sequence SET SEQ=10 WHERE name='\(SQLiteTests.testTable.name)';"
        try? SQLiteTests.sqlite?.query(sql: sqlStatementUpdate)
        
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatementInsert, params: ["searchId", 1, "jsonString"])
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatementInsert, params: ["searchId", 1, "jsonString"])
        
        seq = try? SQLiteTests.sqlite?.getRowCountWithCondition(sql: sqlStatementSelect)
        XCTAssertNotNil(seq)
        XCTAssertEqual(seq!, 12)
        lastInsertId = SQLiteTests.sqlite?.getLastInsertID()
        XCTAssertNotNil(lastInsertId)
        XCTAssertEqual(lastInsertId!, 12)
    }
}
