import XCTest
@testable import ImageSearch

class SQLiteTests: XCTestCase {
    
    static let testDBPath = try! (FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("testDB.sqlite")).path
    static let sqlite = try? SQLite(path: SQLiteTests.testDBPath)
    
    static let testTable = SQLTable(
        name: "TestTable",
        columns: [
            ("id", .INT),
            ("searchId", .TEXT),
            ("sortId", .INT),
            ("json", .TEXT)
        ]
    )
    static let sqlCreateTestTable = """
        CREATE TABLE IF NOT EXISTS "\(SQLiteTests.testTable.name)"(
            "\(SQLiteTests.testTable.primaryKey)" INTEGER NOT NULL,
            "searchId" CHAR(255) NOT NULL,
            "sortId" INT NOT NULL,
            "json" TEXT NOT NULL,
            PRIMARY KEY("\(SQLiteTests.testTable.primaryKey)" AUTOINCREMENT)
        );
        """
    
    static let testTable2 = SQLTable(
        name: "TestTable2",
        columns: [
            ("rowid", .INT),
            ("jsonData", .BLOB),
            ("isDeleted", .BOOL),
            ("updated", .DATE)
        ],
        primaryKey: "rowid"
    )
    static let sqlCreateTestTable2 = """
        CREATE TABLE IF NOT EXISTS "\(SQLiteTests.testTable2.name)"(
            "\(SQLiteTests.testTable2.primaryKey)" INTEGER NOT NULL,
            "jsonData" BLOB NULL,
            "isDeleted" BOOLEAN DEFAULT 0 NOT NULL CHECK (isDeleted IN (0, 1)),
            "updated" DATE NOT NULL,
            PRIMARY KEY("\(SQLiteTests.testTable2.primaryKey)" AUTOINCREMENT)
        );
        """
    
    static let testTable3 = SQLTable(
        name: "TestTable3",
        columns: [
            ("id", .INT),
            ("intColumn", .INT),
            ("boolColumn", .BOOL),
            ("textColumn", .TEXT),
            ("realColumn", .REAL),
            ("blobColumn", .BLOB),
            ("dateColumn", .DATE),
        ]
    )
    static let sqlCreateTestTable3 = """
        CREATE TABLE IF NOT EXISTS "\(SQLiteTests.testTable3.name)"(
            "\(SQLiteTests.testTable3.primaryKey)" INTEGER NOT NULL,
            "intColumn" INTEGER NULL,
            "boolColumn" BOOLEAN NULL,
            "textColumn" TEXT NULL,
            "realColumn" DOUBLE NULL,
            "blobColumn" BLOB NULL,
            "dateColumn" DATE NULL,
            PRIMARY KEY("\(SQLiteTests.testTable3.primaryKey)" AUTOINCREMENT)
        );
        """

    override func setUp() {
        super.setUp()
        try? SQLiteTests.sqlite?.deleteAllRows(in: SQLiteTests.testTable)
        try? SQLiteTests.sqlite?.deleteAllRows(in: SQLiteTests.testTable2)
        try? SQLiteTests.sqlite?.deleteAllRows(in: SQLiteTests.testTable3)
    }
    
    func testCreateTable() {
        // TestTable
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlCreateTestTable)
        var checkIfTableExists = try? SQLiteTests.sqlite?.checkIfTableExists(SQLiteTests.testTable)
        XCTAssertNotNil(checkIfTableExists)
        XCTAssertTrue(checkIfTableExists!)
        
        // TestTable2
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlCreateTestTable2)
        checkIfTableExists = try? SQLiteTests.sqlite?.checkIfTableExists(SQLiteTests.testTable2)
        XCTAssertNotNil(checkIfTableExists)
        XCTAssertTrue(checkIfTableExists!)
        
        // TestTable3
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlCreateTestTable3)
        checkIfTableExists = try? SQLiteTests.sqlite?.checkIfTableExists(SQLiteTests.testTable3)
        XCTAssertNotNil(checkIfTableExists)
        XCTAssertTrue(checkIfTableExists!)
    }
    
    func testCreateTable_whenInvalidTableName() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlCreateTestTable)
        let someTable = SQLTable(name: "SomeTable", columns: [])
        let checkIfTableExists = try? SQLiteTests.sqlite?.checkIfTableExists(someTable)
        XCTAssertNotNil(checkIfTableExists)
        XCTAssertFalse(checkIfTableExists!)
    }
    
    func testDropTable() {
        // TestTable
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlCreateTestTable)
        try? SQLiteTests.sqlite?.dropTable(SQLiteTests.testTable)
        var checkIfTableExists = try? SQLiteTests.sqlite?.checkIfTableExists(SQLiteTests.testTable)
        XCTAssertNotNil(checkIfTableExists)
        XCTAssertFalse(checkIfTableExists!)
        
        // TestTable2
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlCreateTestTable2)
        try? SQLiteTests.sqlite?.dropTable(SQLiteTests.testTable2)
        checkIfTableExists = try? SQLiteTests.sqlite?.checkIfTableExists(SQLiteTests.testTable2)
        XCTAssertNotNil(checkIfTableExists)
        XCTAssertFalse(checkIfTableExists!)
        
        // TestTable3
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlCreateTestTable3)
        try? SQLiteTests.sqlite?.dropTable(SQLiteTests.testTable3)
        checkIfTableExists = try? SQLiteTests.sqlite?.checkIfTableExists(SQLiteTests.testTable3)
        XCTAssertNotNil(checkIfTableExists)
        XCTAssertFalse(checkIfTableExists!)
    }
    
    func testDeleteAllRows() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
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
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlCreateTestTable)
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
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlCreateTestTable)
        try? SQLiteTests.sqlite?.addIndex(to: SQLiteTests.testTable, forColumn: "searchId")
        try? SQLiteTests.sqlite?.endTransaction()
        
        let checkIfIndexExists = try? SQLiteTests.sqlite?.checkIfIndexExists(in: SQLiteTests.testTable, indexName: "some_index")
        XCTAssertNotNil(checkIfIndexExists)
        XCTAssertFalse(checkIfIndexExists!)
    }
    
    func testInsertRow() {
        // TestTable
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
        var rowCount = try? SQLiteTests.sqlite?.getRowCount(in: SQLiteTests.testTable)
        XCTAssertNotNil(rowCount)
        XCTAssertEqual(rowCount!, 0)
        
        var sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 5, "jsonString"])
        
        rowCount = try? SQLiteTests.sqlite?.getRowCount(in: SQLiteTests.testTable)
        XCTAssertNotNil(rowCount)
        XCTAssertEqual(rowCount!, 1)
        
        var row = try? SQLiteTests.sqlite?.getByID(from: SQLiteTests.testTable, id: 1)
        XCTAssertNotNil(row)
        XCTAssertEqual(row!.count, 4)
        XCTAssertEqual(row![0].value as! Int, 1) // "id" INTEGER NOT NULL
        XCTAssertEqual(row![1].value as! String, "searchId") // "searchId" CHAR(255) NOT NULL
        XCTAssertEqual(row![2].value as! Int, 5) // "sortId" INT NOT NULL
        XCTAssertEqual(row![3].value as! String, "jsonString") // "json" TEXT NOT NULL
        
        // TestTable2
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlCreateTestTable2)
        
        sqlStatement = "INSERT INTO \(SQLiteTests.testTable2.name) (jsonData, updated) VALUES (?, ?);"
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["jsonString".data(using: .utf8)!, Date()])
        
        row = try? SQLiteTests.sqlite?.getByID(from: SQLiteTests.testTable2, id: 1)
        XCTAssertNotNil(row)
        XCTAssertEqual(row!.count, 4)
        XCTAssertEqual(row![0].value as! Int, 1) // "rowid" INTEGER NOT NULL
        XCTAssertEqual(String(data: (row![1].value as! Data), encoding: .utf8), "jsonString") // "jsonData" BLOB NULL
        XCTAssertEqual(row![2].value as! Bool, false) // "isDeleted" BOOLEAN DEFAULT 0 NOT NULL
        XCTAssertEqual((row![3].value as! Date).stripTime(), Date().stripTime()) // "updated" DATE NOT NULL
    }
    
    func testInsertRow_whenInvalidSqlStatement() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
        let sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json, other) VALUES (?, ?, ?, ?);"
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 5, "jsonString", ""])
        
        let rowCount = try? SQLiteTests.sqlite?.getRowCount(in: SQLiteTests.testTable)
        XCTAssertNotNil(rowCount)
        XCTAssertEqual(rowCount!, 0)
    }
    
    func testReplaceRow() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
        var rowCount = try? SQLiteTests.sqlite?.getRowCount(in: SQLiteTests.testTable)
        XCTAssertNotNil(rowCount)
        XCTAssertEqual(rowCount!, 0)
        
        var sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let lastInsertId = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString"])
        XCTAssertNotNil(lastInsertId)
        
        sqlStatement = "INSERT OR REPLACE INTO \(SQLiteTests.testTable.name) (\(SQLiteTests.testTable.primaryKey), searchId, sortId, json) VALUES (?, ?, ?, ?);"
        let lastInsertId2 = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: [lastInsertId!, "searchId_1", 2, "jsonString_1"])
        XCTAssertEqual(lastInsertId, lastInsertId2)
        
        rowCount = try? SQLiteTests.sqlite?.getRowCount(in: SQLiteTests.testTable)
        XCTAssertNotNil(rowCount)
        XCTAssertEqual(rowCount!, 1)
        
        let row = try? SQLiteTests.sqlite?.getByID(from: SQLiteTests.testTable, id: lastInsertId!)
        XCTAssertNotNil(row)
        XCTAssertEqual(row!.count, 4)
        XCTAssertEqual(row![0].value as! Int, 1) // "id" INTEGER NOT NULL
        XCTAssertEqual(row![1].value as! String, "searchId_1") // "searchId" CHAR(255) NOT NULL
        XCTAssertEqual(row![2].value as! Int, 2) // "sortId" INT NOT NULL
        XCTAssertEqual(row![3].value as! String, "jsonString_1") // "json" TEXT NOT NULL
    }
    
    func testUpdateRow() {
        // TestTable
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
        var sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 5, "jsonString"])
        
        sqlStatement = "UPDATE \(SQLiteTests.testTable.name) SET searchId = ?, sortId = ?, json = ? WHERE \(SQLiteTests.testTable.primaryKey) = ?"
        try? SQLiteTests.sqlite?.updateRow(sql: sqlStatement, params: ["searchId_1", 7, "jsonString_1", 1])
        
        var row = try? SQLiteTests.sqlite?.getByID(from: SQLiteTests.testTable, id: 1)
        XCTAssertNotNil(row)
        XCTAssertEqual(row!.count, 4)
        XCTAssertEqual(row![0].value as! Int, 1) // "id" INTEGER NOT NULL
        XCTAssertEqual(row![1].value as! String, "searchId_1") // "searchId" CHAR(255) NOT NULL
        XCTAssertEqual(row![2].value as! Int, 7) // "sortId" INT NOT NULL
        XCTAssertEqual(row![3].value as! String, "jsonString_1") // "json" TEXT NOT NULL
        
        // TestTable2
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlCreateTestTable2)
        
        let insertDate = Date()
        sqlStatement = "INSERT INTO \(SQLiteTests.testTable2.name) (jsonData, updated) VALUES (?, ?);"
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["jsonString".data(using: .utf8)!, insertDate])
        
        let updateDate = Date()
        sqlStatement = "UPDATE \(SQLiteTests.testTable2.name) SET jsonData = NULL, isDeleted = ?, updated = ? WHERE \(SQLiteTests.testTable2.primaryKey) = ?"
        try? SQLiteTests.sqlite?.updateRow(sql: sqlStatement, params: [true, updateDate, 1])
        /* Another option to do the same:
        sqlStatement = "UPDATE \(SQLiteTests.testTable2.name) SET jsonData = ?, isDeleted = ?, updated = ? WHERE \(SQLiteTests.testTable2.primaryKey) = ?"
        try? SQLiteTests.sqlite?.updateRow(sql: sqlStatement, params: [nil, true, updateDate, 1])
         */
        
        row = try? SQLiteTests.sqlite?.getByID(from: SQLiteTests.testTable2, id: 1)
        XCTAssertNotNil(row)
        XCTAssertEqual(row!.count, 4)
        XCTAssertEqual(row![0].value as! Int, 1) // "rowid" INTEGER NOT NULL
        XCTAssertEqual(row![1].value as? Data, nil) // "jsonData" BLOB NULL
        XCTAssertEqual(row![2].value as! Bool, true) // "isDeleted" BOOLEAN DEFAULT 0 NOT NULL
        XCTAssertEqual((row![3].value as! Date).stripTime(), updateDate.stripTime()) // "updated" DATE NOT NULL
    }
    
    func testUpdateRow_whenInvalidId() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
        var sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 5, "jsonString"])
        
        sqlStatement = "UPDATE \(SQLiteTests.testTable.name) SET searchId = ?, sortId = ?, json = ? WHERE \(SQLiteTests.testTable.primaryKey) = ?"
        try? SQLiteTests.sqlite?.updateRow(sql: sqlStatement, params: ["searchId_1", 7, "jsonString_1", 2])
        
        let row = try? SQLiteTests.sqlite?.getByID(from: SQLiteTests.testTable, id: 1)
        XCTAssertNotNil(row)
        XCTAssertEqual(row!.count, 4)
        XCTAssertEqual(row![0].value as! Int, 1) // "id" INTEGER NOT NULL
        XCTAssertEqual(row![1].value as! String, "searchId") // "searchId" CHAR(255) NOT NULL
        XCTAssertEqual(row![2].value as! Int, 5) // "sortId" INT NOT NULL
        XCTAssertEqual(row![3].value as! String, "jsonString") // "json" TEXT NOT NULL
    }
    
    func testUpdateAllRows() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlCreateTestTable2)
        
        var sqlStatement = "INSERT INTO \(SQLiteTests.testTable2.name) (jsonData, updated) VALUES (?, ?);"
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["jsonString".data(using: .utf8)!, Date()])
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["jsonString_1".data(using: .utf8)!, Date()])
        
        sqlStatement = "UPDATE \(SQLiteTests.testTable2.name) SET isDeleted = ?, updated = ?"
        try? SQLiteTests.sqlite?.updateRow(sql: sqlStatement, params: [true, Date()])
        if let updateChanges = SQLiteTests.sqlite?.getChanges() {
            XCTAssertEqual(updateChanges, 2)
        }
        
        sqlStatement = "SELECT * FROM \(SQLiteTests.testTable2.name)"
        let rows = try? SQLiteTests.sqlite?.getAllRows(from: SQLiteTests.testTable2)
        XCTAssertNotNil(rows)
        XCTAssertEqual(rows!.count, 2)
        
        let firstRow = rows![0]
        XCTAssertEqual(firstRow.count, 4)
        XCTAssertEqual(firstRow[0].value as! Int, 1) // "rowid" INTEGER NOT NULL
        XCTAssertEqual(String(data: (firstRow[1].value as! Data), encoding: .utf8), "jsonString")
        XCTAssertEqual(firstRow[2].value as! Bool, true) // "isDeleted" BOOLEAN DEFAULT 0 NOT NULL
        XCTAssertEqual((firstRow[3].value as! Date).stripTime(), Date().stripTime()) // "updated" DATE NOT NULL
        
        let secondRow = rows![1]
        XCTAssertEqual(secondRow.count, 4)
        XCTAssertEqual(secondRow[0].value as! Int, 2) // "rowid" INTEGER NOT NULL
        XCTAssertEqual(String(data: (secondRow[1].value as! Data), encoding: .utf8), "jsonString_1")
        XCTAssertEqual(secondRow[2].value as! Bool, true) // "isDeleted" BOOLEAN DEFAULT 0 NOT NULL
        XCTAssertEqual((secondRow[3].value as! Date).stripTime(), Date().stripTime()) // "updated" DATE NOT NULL
    }
    
    func testDeleteRow() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
        var sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString"])
                
        sqlStatement = "DELETE FROM \(SQLiteTests.testTable.name) WHERE searchId = ?;"
        try? SQLiteTests.sqlite?.deleteRow(sql: sqlStatement, params: ["searchId"])
        
        let rowCount = try? SQLiteTests.sqlite?.getRowCount(in: SQLiteTests.testTable)
        XCTAssertNotNil(rowCount)
        XCTAssertEqual(rowCount!, 0)
    }
    
    func testDeleteRow_whenInvalidSqlStatement() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
        var sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString"])
                
        sqlStatement = "DELETE FROM \(SQLiteTests.testTable.name) WHERE someColumn = ?;"
        try? SQLiteTests.sqlite?.deleteRow(sql: sqlStatement, params: ["searchId"])
        
        let rowCount = try? SQLiteTests.sqlite?.getRowCount(in: SQLiteTests.testTable)
        XCTAssertNotNil(rowCount)
        XCTAssertEqual(rowCount!, 1)
    }
    
    func testDeleteByID() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
        let sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString"])
        
        try? SQLiteTests.sqlite?.deleteByID(in: SQLiteTests.testTable, id: 1)
        
        let rowCount = try? SQLiteTests.sqlite?.getRowCount(in: SQLiteTests.testTable)
        XCTAssertNotNil(rowCount)
        XCTAssertEqual(rowCount!, 0)
    }
    
    func testDeleteByID_whenInvalidId() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
        let sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString"])
        
        try? SQLiteTests.sqlite?.deleteByID(in: SQLiteTests.testTable, id: 2)
        
        let rowCount = try? SQLiteTests.sqlite?.getRowCount(in: SQLiteTests.testTable)
        XCTAssertNotNil(rowCount)
        XCTAssertEqual(rowCount!, 1)
    }
    
    func testGetRowCount() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
        let sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString"])
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString"])
        
        let rowCount = try? SQLiteTests.sqlite?.getRowCount(in: SQLiteTests.testTable)
        XCTAssertNotNil(rowCount)
        XCTAssertEqual(rowCount!, 2)
    }
    
    func testGetRowCountWithCondition() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
        var sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString_1"])
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 2, "jsonString_2"])
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId_1", 1, "jsonString_3"])
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId_1", 2, "jsonString_4"])
        
        var rowCount = try? SQLiteTests.sqlite?.getRowCount(in: SQLiteTests.testTable)
        XCTAssertNotNil(rowCount)
        XCTAssertEqual(rowCount!, 4)
        
        sqlStatement = "SELECT COUNT(*) FROM \(SQLiteTests.testTable.name) WHERE searchId = ?;"
        rowCount = try? SQLiteTests.sqlite?.getRowCountWithCondition(sql: sqlStatement, params: ["searchId_1"])
        XCTAssertNotNil(rowCount)
        XCTAssertEqual(rowCount!, 2)
    }
    
    func testGetRowCountWithCondition_whenInvalidCondition() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
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
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
        var sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString_1"])
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 2, "jsonString_2"])
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId_1", 1, "jsonString_3"])
        
        sqlStatement = "SELECT * FROM \(SQLiteTests.testTable.name) WHERE searchId = ? ORDER BY sortId ASC;"
        
        let rows = try? SQLiteTests.sqlite?.getRow(from: SQLiteTests.testTable, sql: sqlStatement, params: ["searchId"])
        XCTAssertNotNil(rows)
        XCTAssertEqual(rows!.count, 2)
        
        let firstRow = rows![0]
        XCTAssertEqual(firstRow.count, 4)
        XCTAssertEqual(firstRow[0].value as! Int, 1) // "id" INTEGER NOT NULL
        XCTAssertEqual(firstRow[1].value as! String, "searchId") // "searchId" CHAR(255) NOT NULL
        XCTAssertEqual(firstRow[2].value as! Int, 1) // "sortId" INT NOT NULL
        XCTAssertEqual(firstRow[3].value as! String, "jsonString_1") // "json" TEXT NOT NULL
    }
    
    func testGetRow_whenOrderIsDESC() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
        var sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString_1"])
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 2, "jsonString_2"])
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId_1", 1, "jsonString_3"])
        
        sqlStatement = "SELECT * FROM \(SQLiteTests.testTable.name) WHERE searchId = ? ORDER BY sortId DESC;"
        
        let rows = try? SQLiteTests.sqlite?.getRow(from: SQLiteTests.testTable, sql: sqlStatement, params: ["searchId"])
        XCTAssertNotNil(rows)
        XCTAssertEqual(rows!.count, 2)
        
        let firstRow = rows![0]
        XCTAssertEqual(firstRow.count, 4)
        XCTAssertEqual(firstRow[0].value as! Int, 2) // "id" INTEGER NOT NULL
        XCTAssertEqual(firstRow[1].value as! String, "searchId") // "searchId" CHAR(255) NOT NULL
        XCTAssertEqual(firstRow[2].value as! Int, 2) // "sortId" INT NOT NULL
        XCTAssertEqual(firstRow[3].value as! String, "jsonString_2") // "json" TEXT NOT NULL
    }
    
    func testGetRow_whenReturnValueIsNULL() {
        // TestTable2
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlCreateTestTable2)
        
        var sqlStatement = "INSERT INTO \(SQLiteTests.testTable2.name) (updated) VALUES (?);" // Without specifying a value, jsonData will be NULL
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: [Date()])
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: [Date()])
        
        sqlStatement = "SELECT * FROM \(SQLiteTests.testTable2.name) WHERE isDeleted = ?"
        var rows = try? SQLiteTests.sqlite?.getRow(from: SQLiteTests.testTable2, sql: sqlStatement, params: [false])
        XCTAssertNotNil(rows)
        XCTAssertEqual(rows!.count, 2)
        if let firstRow = rows!.first {
            XCTAssertEqual(firstRow.count, 4)
            XCTAssertEqual(firstRow[0].value as! Int, 1) // "rowid" INTEGER NOT NULL
            XCTAssertEqual(firstRow[1].value as? Data, nil) // "jsonData" BLOB NULL
            XCTAssertEqual(firstRow[2].value as! Bool, false) // "isDeleted" BOOLEAN DEFAULT 0 NOT NULL
            XCTAssertEqual((firstRow[3].value as! Date).stripTime(), Date().stripTime()) // "updated" DATE NOT NULL
        } else {
            XCTFail()
        }
        
        // TestTable3
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlCreateTestTable3)
        
        sqlStatement = "INSERT INTO \(SQLiteTests.testTable3.name) (id) VALUES (?);" // id will be autoincremented, all nullable values will be NULL
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement)
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement)
        
        sqlStatement = "SELECT * FROM \(SQLiteTests.testTable3.name)"
        rows = try? SQLiteTests.sqlite?.getRow(from: SQLiteTests.testTable3, sql: sqlStatement)
        XCTAssertNotNil(rows)
        XCTAssertEqual(rows!.count, 2)
        if let firstRow = rows!.first {
            XCTAssertEqual(firstRow.count, 7)
            XCTAssertEqual(firstRow[0].value as! Int, 1) // "id" INTEGER NOT NULL
            XCTAssertEqual(firstRow[1].value as? Int, nil) // "intValue" INTEGER NULL
            XCTAssertEqual(firstRow[2].value as? Bool, nil) // "boolValue" BOOLEAN NULL
            XCTAssertEqual(firstRow[3].value as? String, nil) // "textColumn" TEXT NULL
            XCTAssertEqual(firstRow[4].value as? Double, nil) // "realColumn" DOUBLE NULL
            XCTAssertEqual(firstRow[5].value as? Data, nil) // "blobColumn" BLOB NULL
            XCTAssertEqual(firstRow[6].value as? Date, nil) // "dateColumn" DATE NULL
        } else {
            XCTFail()
        }
    }
    
    func testGetRow_whenSpecifyingSpecificColumns() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
        var sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString_1"])
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 2, "jsonString_2"])
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId_1", 1, "jsonString_3"])
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId_1", 2, "jsonString_4"])
        
        sqlStatement = "SELECT id, sortId, json FROM \(SQLiteTests.testTable.name) WHERE searchId = ?;"
        let rows = try? SQLiteTests.sqlite?.getRow(from: SQLiteTests.testTable, sql: sqlStatement, params: ["searchId"])
        XCTAssertNotNil(rows)
        XCTAssertEqual(rows!.count, 2)
        
        let firstRow = rows![0]
        XCTAssertEqual(firstRow.count, 3)
        XCTAssertEqual(firstRow[0].value as! Int, 1) // "id" INTEGER NOT NULL
        XCTAssertEqual(firstRow[1].value as! Int, 1) // "sortId" INT NOT NULL
        XCTAssertEqual(firstRow[2].value as! String, "jsonString_1") // "json" TEXT NOT NULL
    }
    
    func testGetRow_whenInvalidCondition() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
        var sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString_1"])
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 2, "jsonString_2"])
        
        sqlStatement = "SELECT * FROM \(SQLiteTests.testTable.name) WHERE searchId = ?;"
        let rows = try? SQLiteTests.sqlite?.getRow(from: SQLiteTests.testTable, sql: sqlStatement, params: ["someId"])
        XCTAssertNotNil(rows)
        XCTAssertEqual(rows!.count, 0)
    }
    
    func testGetAllRows() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
        let sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString_1"])
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 2, "jsonString_2"])
        
        let rows = try? SQLiteTests.sqlite?.getAllRows(from: SQLiteTests.testTable)
        XCTAssertNotNil(rows)
        XCTAssertEqual(rows!.count, 2)
        
        let firstRow = rows![0]
        XCTAssertEqual(firstRow.count, 4)
        XCTAssertEqual(firstRow[0].value as! Int, 1) // "id" INTEGER NOT NULL
        XCTAssertEqual(firstRow[1].value as! String, "searchId") // "searchId" CHAR(255) NOT NULL
        XCTAssertEqual(firstRow[2].value as! Int, 1) // "sortId" INT NOT NULL
        XCTAssertEqual(firstRow[3].value as! String, "jsonString_1") // "json" TEXT NOT NULL
        
        let secondRow = rows![1]
        XCTAssertEqual(secondRow.count, 4)
        XCTAssertEqual(secondRow[0].value as! Int, 2) // "id" INTEGER NOT NULL
        XCTAssertEqual(secondRow[1].value as! String, "searchId") // "searchId" CHAR(255) NOT NULL
        XCTAssertEqual(secondRow[2].value as! Int, 2) // "sortId" INT NOT NULL
        XCTAssertEqual(secondRow[3].value as! String, "jsonString_2") // "json" TEXT NOT NULL
    }
    
    func testGetByID() {
        // TestTable
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
        var sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString_1"])
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 2, "jsonString_2"])
        
        var row = try? SQLiteTests.sqlite?.getByID(from: SQLiteTests.testTable, id: 1)
        XCTAssertNotNil(row)
        XCTAssertEqual(row!.count, 4)
        XCTAssertEqual(row![0].value as! Int, 1) // "id" INTEGER NOT NULL
        XCTAssertEqual(row![1].value as! String, "searchId") // "searchId" CHAR(255) NOT NULL
        XCTAssertEqual(row![2].value as! Int, 1) // "sortId" INT NOT NULL
        XCTAssertEqual(row![3].value as! String, "jsonString_1") // "json" TEXT NOT NULL
        
        row = try? SQLiteTests.sqlite?.getByID(from: SQLiteTests.testTable, id: 2)
        XCTAssertNotNil(row)
        XCTAssertEqual(row!.count, 4)
        XCTAssertEqual(row![0].value as! Int, 2) // "id" INTEGER NOT NULL
        XCTAssertEqual(row![1].value as! String, "searchId") // "searchId" CHAR(255) NOT NULL
        XCTAssertEqual(row![2].value as! Int, 2) // "sortId" INT NOT NULL
        XCTAssertEqual(row![3].value as! String, "jsonString_2") // "json" TEXT NOT NULL
        
        // TestTable2
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlCreateTestTable2)
        
        sqlStatement = "INSERT INTO \(SQLiteTests.testTable2.name) (jsonData, updated) VALUES (?, ?);"
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["jsonString".data(using: .utf8)!, Date()])
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["jsonString_1".data(using: .utf8)!, Date()])
        
        row = try? SQLiteTests.sqlite?.getByID(from: SQLiteTests.testTable2, id: 2)
        XCTAssertNotNil(row)
        XCTAssertEqual(row!.count, 4)
        XCTAssertEqual(row![0].value as! Int, 2) // "rowid" INTEGER NOT NULL
        XCTAssertEqual(String(data: (row![1].value as! Data), encoding: .utf8), "jsonString_1") // "jsonData" BLOB NULL
        XCTAssertEqual(row![2].value as! Bool, false) // "isDeleted" BOOLEAN DEFAULT 0 NOT NULL
        XCTAssertEqual((row![3].value as! Date).stripTime(), Date().stripTime()) // "updated" DATE NOT NULL
    }
    
    func testGetByID_whenInvalidId() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
        let sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString_1"])
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["searchId", 2, "jsonString_2"])
        
        let row = try? SQLiteTests.sqlite?.getByID(from: SQLiteTests.testTable, id: 3)
        XCTAssertNil(row)
    }
    
    func testGetLastRow() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
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
        XCTAssertEqual(row![0].value as! Int, 3) // "id" INTEGER NOT NULL
        XCTAssertEqual(row![1].value as! String, "searchId") // "searchId" CHAR(255) NOT NULL
        XCTAssertEqual(row![2].value as! Int, 3) // "sortId" INT NOT NULL
        XCTAssertEqual(row![3].value as! String, "jsonString_3") // "json" TEXT NOT NULL
    }
    
    func testGetLastInsertId() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
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
    
    func testGetChangesAndGetTotalChanges() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlCreateTestTable2)
        
        var sqlStatement = "INSERT INTO \(SQLiteTests.testTable2.name) (jsonData, updated) VALUES (?, ?);"
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["jsonString".data(using: .utf8)!, Date()])
        let _ = try? SQLiteTests.sqlite?.insertRow(sql: sqlStatement, params: ["jsonString_1".data(using: .utf8)!, Date()])
        
        sqlStatement = "UPDATE \(SQLiteTests.testTable2.name) SET isDeleted = ?, updated = ?"
        try? SQLiteTests.sqlite?.updateRow(sql: sqlStatement, params: [true, Date()])
        
        let updateChanges = SQLiteTests.sqlite?.getChanges()
        XCTAssertNotNil(updateChanges)
        XCTAssertEqual(updateChanges!, 2)
        
        let updateTotalChanges = SQLiteTests.sqlite?.getTotalChanges()
        XCTAssertNotNil(updateTotalChanges)
        XCTAssertTrue(updateTotalChanges! >= 4)
    }
    
    func testResetAutoincrement() {
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
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
        try? SQLiteTests.sqlite?.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
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


