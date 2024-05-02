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
            "updated" DATETIME NOT NULL,
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
            "dateColumn" DATETIME NULL,
            PRIMARY KEY("\(SQLiteTests.testTable3.primaryKey)" AUTOINCREMENT)
        );
        """

    override func setUp() {
        super.setUp()
        guard let sqlite = SQLiteTests.sqlite else { return }
        try? sqlite.deleteAllRows(in: SQLiteTests.testTable)
        try? sqlite.deleteAllRows(in: SQLiteTests.testTable2)
        try? sqlite.deleteAllRows(in: SQLiteTests.testTable3)
    }
    
    func testCreateTable() {
        guard let sqlite = SQLiteTests.sqlite else { return }
        
        // TestTable
        try? sqlite.createTable(sql: SQLiteTests.sqlCreateTestTable)
        var checkIfTableExists = try? sqlite.checkIfTableExists(SQLiteTests.testTable)
        XCTAssertTrue(checkIfTableExists!)
        
        // TestTable2
        try? sqlite.createTable(sql: SQLiteTests.sqlCreateTestTable2)
        checkIfTableExists = try? sqlite.checkIfTableExists(SQLiteTests.testTable2)
        XCTAssertTrue(checkIfTableExists!)
        
        // TestTable3
        try? sqlite.createTable(sql: SQLiteTests.sqlCreateTestTable3)
        checkIfTableExists = try? sqlite.checkIfTableExists(SQLiteTests.testTable3)
        XCTAssertTrue(checkIfTableExists!)
    }
    
    func testCreateTable_whenInvalidTableName() {
        guard let sqlite = SQLiteTests.sqlite else { return }
        try? sqlite.createTable(sql: SQLiteTests.sqlCreateTestTable)
        let someTable = SQLTable(name: "SomeTable", columns: [])
        let checkIfTableExists = try? sqlite.checkIfTableExists(someTable)
        XCTAssertFalse(checkIfTableExists!)
    }
    
    func testDropTable() {
        guard let sqlite = SQLiteTests.sqlite else { return }
        
        // TestTable
        try? sqlite.createTable(sql: SQLiteTests.sqlCreateTestTable)
        try? sqlite.dropTable(SQLiteTests.testTable)
        var checkIfTableExists = try? sqlite.checkIfTableExists(SQLiteTests.testTable)
        XCTAssertFalse(checkIfTableExists!)
        
        // TestTable2
        try? sqlite.createTable(sql: SQLiteTests.sqlCreateTestTable2)
        try? sqlite.dropTable(SQLiteTests.testTable2)
        checkIfTableExists = try? sqlite.checkIfTableExists(SQLiteTests.testTable2)
        XCTAssertFalse(checkIfTableExists!)
        
        // TestTable3
        try? sqlite.createTable(sql: SQLiteTests.sqlCreateTestTable3)
        try? sqlite.dropTable(SQLiteTests.testTable3)
        checkIfTableExists = try? sqlite.checkIfTableExists(SQLiteTests.testTable3)
        XCTAssertFalse(checkIfTableExists!)
    }
    
    func testIndexesAndTransactions() {
        guard let sqlite = SQLiteTests.sqlite else { return }
        
        let columnName = "searchId"
        try? sqlite.beginTransaction()
        try? sqlite.createTable(sql: SQLiteTests.sqlCreateTestTable)
        try? sqlite.addIndex(to: SQLiteTests.testTable, forColumn: columnName)
        try? sqlite.endTransaction()
        
        let indexName = "\(SQLiteTests.testTable.name)_\(columnName)_idx"
        
        var checkIfIndexExists = try? sqlite.checkIfIndexExists(in: SQLiteTests.testTable, indexName: indexName)
        XCTAssertTrue(checkIfIndexExists!)
        
        try? sqlite.dropIndex(in: SQLiteTests.testTable, forColumn: columnName)
        
        checkIfIndexExists = try? sqlite.checkIfIndexExists(in: SQLiteTests.testTable, indexName: indexName)
        XCTAssertFalse(checkIfIndexExists!)
    }
    
    func testIndexesAndTransactions_whenInvalidIndexName() {
        guard let sqlite = SQLiteTests.sqlite else { return }
        
        try? sqlite.beginTransaction()
        try? sqlite.createTable(sql: SQLiteTests.sqlCreateTestTable)
        try? sqlite.addIndex(to: SQLiteTests.testTable, forColumn: "searchId")
        try? sqlite.endTransaction()
        
        let checkIfIndexExists = try? sqlite.checkIfIndexExists(in: SQLiteTests.testTable, indexName: "some_index")
        XCTAssertFalse(checkIfIndexExists!)
    }
    
    func testInsertRow() {
        guard let sqlite = SQLiteTests.sqlite else { return }
        
        // TestTable
        try? sqlite.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
        var sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId", 5, "jsonString"])
        
        var rowCount = try? sqlite.getRowCount(in: SQLiteTests.testTable)
        XCTAssertEqual(rowCount!, 1)
        
        var row = try? sqlite.getByID(from: SQLiteTests.testTable, id: 1)
        XCTAssertEqual(row!.count, 4)
        XCTAssertEqual(row![0].value as! Int, 1) // "id" INTEGER NOT NULL
        XCTAssertEqual(row![1].value as! String, "searchId") // "searchId" CHAR(255) NOT NULL
        XCTAssertEqual(row![2].value as! Int, 5) // "sortId" INT NOT NULL
        XCTAssertEqual(row![3].value as! String, "jsonString") // "json" TEXT NOT NULL
        
        // TestTable2
        try? sqlite.createTable(sql: SQLiteTests.sqlCreateTestTable2)
        
        sqlStatement = "INSERT INTO \(SQLiteTests.testTable2.name) (jsonData, updated) VALUES (?, ?);"
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["jsonString".data(using: .utf8)!, Date()])
        
        rowCount = try? sqlite.getRowCount(in: SQLiteTests.testTable2)
        XCTAssertEqual(rowCount!, 1)
        
        row = try? sqlite.getByID(from: SQLiteTests.testTable2, id: 1)
        XCTAssertEqual(row!.count, 4)
        XCTAssertEqual(row![0].value as! Int, 1) // "rowid" INTEGER NOT NULL
        XCTAssertEqual(String(data: (row![1].value as! Data), encoding: .utf8), "jsonString") // "jsonData" BLOB NULL
        XCTAssertEqual(row![2].value as! Bool, false) // "isDeleted" BOOLEAN DEFAULT 0 NOT NULL
        XCTAssertTrue((row![3].value as! Date) <= Date()) // "updated" DATETIME NOT NULL
    }
    
    func testInsertRow_whenInvalidSqlStatement() {
        guard let sqlite = SQLiteTests.sqlite else { return }
        try? sqlite.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
        let sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json, other) VALUES (?, ?, ?, ?);"
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId", 5, "jsonString", ""])
        
        let rowCount = try? sqlite.getRowCount(in: SQLiteTests.testTable)
        XCTAssertEqual(rowCount!, 0)
    }
    
    func testInsertRow_whenInsertingMultipleRows() {
        guard let sqlite = SQLiteTests.sqlite else { return }
        try? sqlite.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
        let sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?), (?, ?, ?);"
        let numberOfInsertedRows = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId", 2, "jsonString_2", "searchId", 1, "jsonString_1"])
        XCTAssertEqual(numberOfInsertedRows!, 2)
        
        let rowCount = try? sqlite.getRowCount(in: SQLiteTests.testTable)
        XCTAssertEqual(rowCount!, 2)
        
        let rows = try? sqlite.getAllRows(from: SQLiteTests.testTable)
        XCTAssertEqual(rows!.count, 2)
        let firstRow = rows!.first
        XCTAssertEqual(firstRow!.count, 4)
        XCTAssertEqual(firstRow![0].value as! Int, 1) // "id" INTEGER NOT NULL
        XCTAssertEqual(firstRow![1].value as! String, "searchId") // "searchId" CHAR(255) NOT NULL
        XCTAssertEqual(firstRow![2].value as! Int, 2) // "sortId" INT NOT NULL
        XCTAssertEqual(firstRow![3].value as! String, "jsonString_2") // "json" TEXT NOT NULL
    }
    
    func testReplaceRow() {
        guard let sqlite = SQLiteTests.sqlite else { return }
        try? sqlite.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
        var sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let lastInsertId = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString"])
        XCTAssertEqual(lastInsertId!, 1)
        
        sqlStatement = "INSERT OR REPLACE INTO \(SQLiteTests.testTable.name) (\(SQLiteTests.testTable.primaryKey), searchId, sortId, json) VALUES (?, ?, ?, ?);"
        let lastInsertId2 = try? sqlite.insertRow(sql: sqlStatement, params: [lastInsertId!, "searchId_1", 2, "jsonString_1"])
        XCTAssertEqual(lastInsertId, lastInsertId2)
        
        let rowCount = try? sqlite.getRowCount(in: SQLiteTests.testTable)
        XCTAssertEqual(rowCount!, 1)
        
        let row = try? sqlite.getByID(from: SQLiteTests.testTable, id: lastInsertId!)
        XCTAssertEqual(row!.count, 4)
        XCTAssertEqual(row![0].value as! Int, 1) // "id" INTEGER NOT NULL
        XCTAssertEqual(row![1].value as! String, "searchId_1") // "searchId" CHAR(255) NOT NULL
        XCTAssertEqual(row![2].value as! Int, 2) // "sortId" INT NOT NULL
        XCTAssertEqual(row![3].value as! String, "jsonString_1") // "json" TEXT NOT NULL
    }
    
    func testUpdateRow() {
        guard let sqlite = SQLiteTests.sqlite else { return }
        
        // TestTable
        try? sqlite.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
        var sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId", 5, "jsonString"])
        
        sqlStatement = "UPDATE \(SQLiteTests.testTable.name) SET searchId = ?, sortId = ?, json = ? WHERE \(SQLiteTests.testTable.primaryKey) = ?"
        try? sqlite.updateRow(sql: sqlStatement, params: ["searchId_1", 7, "jsonString_1", 1])
        
        var row = try? sqlite.getByID(from: SQLiteTests.testTable, id: 1)
        XCTAssertEqual(row!.count, 4)
        XCTAssertEqual(row![0].value as! Int, 1) // "id" INTEGER NOT NULL
        XCTAssertEqual(row![1].value as! String, "searchId_1") // "searchId" CHAR(255) NOT NULL
        XCTAssertEqual(row![2].value as! Int, 7) // "sortId" INT NOT NULL
        XCTAssertEqual(row![3].value as! String, "jsonString_1") // "json" TEXT NOT NULL
        
        // TestTable2
        try? sqlite.createTable(sql: SQLiteTests.sqlCreateTestTable2)
        
        let insertDate = Date()
        sqlStatement = "INSERT INTO \(SQLiteTests.testTable2.name) (jsonData, updated) VALUES (?, ?);"
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["jsonString".data(using: .utf8)!, insertDate])
        
        let updateDate = Date()
        sqlStatement = "UPDATE \(SQLiteTests.testTable2.name) SET jsonData = NULL, isDeleted = ?, updated = ? WHERE \(SQLiteTests.testTable2.primaryKey) = ?"
        try? sqlite.updateRow(sql: sqlStatement, params: [true, updateDate, 1])
        /* Another option to do the same:
        sqlStatement = "UPDATE \(SQLiteTests.testTable2.name) SET jsonData = ?, isDeleted = ?, updated = ? WHERE \(SQLiteTests.testTable2.primaryKey) = ?"
        try? sqlite.updateRow(sql: sqlStatement, params: [nil, true, updateDate, 1])
         */
        
        row = try? sqlite.getByID(from: SQLiteTests.testTable2, id: 1)
        XCTAssertEqual(row!.count, 4)
        XCTAssertEqual(row![0].value as! Int, 1) // "rowid" INTEGER NOT NULL
        XCTAssertEqual(row![1].value as? Data, nil) // "jsonData" BLOB NULL
        XCTAssertEqual(row![2].value as! Bool, true) // "isDeleted" BOOLEAN DEFAULT 0 NOT NULL
        XCTAssertEqual((row![3].value as! Date).description, updateDate.description) // "updated" DATETIME NOT NULL
    }
    
    func testUpdateRow_whenInvalidId() {
        guard let sqlite = SQLiteTests.sqlite else { return }
        try? sqlite.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
        var sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId", 5, "jsonString"])
        
        sqlStatement = "UPDATE \(SQLiteTests.testTable.name) SET searchId = ?, sortId = ?, json = ? WHERE \(SQLiteTests.testTable.primaryKey) = ?"
        try? sqlite.updateRow(sql: sqlStatement, params: ["searchId_1", 7, "jsonString_1", 2])
        
        let row = try? sqlite.getByID(from: SQLiteTests.testTable, id: 1)
        XCTAssertEqual(row!.count, 4)
        XCTAssertEqual(row![0].value as! Int, 1) // "id" INTEGER NOT NULL
        XCTAssertEqual(row![1].value as! String, "searchId") // "searchId" CHAR(255) NOT NULL
        XCTAssertEqual(row![2].value as! Int, 5) // "sortId" INT NOT NULL
        XCTAssertEqual(row![3].value as! String, "jsonString") // "json" TEXT NOT NULL
    }
    
    func testUpdateAllRows() {
        guard let sqlite = SQLiteTests.sqlite else { return }
        try? sqlite.createTable(sql: SQLiteTests.sqlCreateTestTable2)
        
        var sqlStatement = "INSERT INTO \(SQLiteTests.testTable2.name) (jsonData, updated) VALUES (?, ?);"
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["jsonString_1".data(using: .utf8)!, Date()])
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["jsonString_2".data(using: .utf8)!, Date()])
        
        sqlStatement = "UPDATE \(SQLiteTests.testTable2.name) SET isDeleted = ?, updated = ?"
        try? sqlite.updateRow(sql: sqlStatement, params: [true, Date()])
        XCTAssertEqual(sqlite.changes, 2)
        
        let rows = try? sqlite.getAllRows(from: SQLiteTests.testTable2)
        XCTAssertEqual(rows!.count, 2)
        
        let firstRow = rows![0]
        XCTAssertEqual(firstRow.count, 4)
        XCTAssertEqual(firstRow[0].value as! Int, 1) // "rowid" INTEGER NOT NULL
        XCTAssertEqual(String(data: (firstRow[1].value as! Data), encoding: .utf8), "jsonString_1") // "jsonData" BLOB NULL
        XCTAssertEqual(firstRow[2].value as! Bool, true) // "isDeleted" BOOLEAN DEFAULT 0 NOT NULL
        XCTAssertTrue((firstRow[3].value as! Date) <= Date()) // "updated" DATETIME NOT NULL
        
        let secondRow = rows![1]
        XCTAssertEqual(secondRow.count, 4)
        XCTAssertEqual(secondRow[0].value as! Int, 2) // "rowid" INTEGER NOT NULL
        XCTAssertEqual(String(data: (secondRow[1].value as! Data), encoding: .utf8), "jsonString_2") // "jsonData" BLOB NULL
        XCTAssertEqual(secondRow[2].value as! Bool, true) // "isDeleted" BOOLEAN DEFAULT 0 NOT NULL
        XCTAssertTrue((secondRow[3].value as! Date) <= Date()) // "updated" DATETIME NOT NULL
    }
    
    func testDeleteRow() {
        guard let sqlite = SQLiteTests.sqlite else { return }
        try? sqlite.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
        var sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString"])
                
        sqlStatement = "DELETE FROM \(SQLiteTests.testTable.name) WHERE searchId = ?;"
        try? sqlite.deleteRow(sql: sqlStatement, params: ["searchId"])
        
        let rowCount = try? sqlite.getRowCount(in: SQLiteTests.testTable)
        XCTAssertEqual(rowCount!, 0)
    }
    
    func testDeleteRow_whenInvalidSqlStatement() {
        guard let sqlite = SQLiteTests.sqlite else { return }
        try? sqlite.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
        var sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString"])
                
        sqlStatement = "DELETE FROM \(SQLiteTests.testTable.name) WHERE someColumn = ?;"
        try? sqlite.deleteRow(sql: sqlStatement, params: ["searchId"])
        
        let rowCount = try? sqlite.getRowCount(in: SQLiteTests.testTable)
        XCTAssertEqual(rowCount!, 1)
    }
    
    func testDeleteByID() {
        guard let sqlite = SQLiteTests.sqlite else { return }
        try? sqlite.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
        let sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString"])
        
        try? sqlite.deleteByID(in: SQLiteTests.testTable, id: 1)
        
        let rowCount = try? sqlite.getRowCount(in: SQLiteTests.testTable)
        XCTAssertEqual(rowCount!, 0)
    }
    
    func testDeleteByID_whenInvalidId() {
        guard let sqlite = SQLiteTests.sqlite else { return }
        try? sqlite.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
        let sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString"])
        
        try? sqlite.deleteByID(in: SQLiteTests.testTable, id: 2)
        
        let rowCount = try? sqlite.getRowCount(in: SQLiteTests.testTable)
        XCTAssertEqual(rowCount!, 1)
    }
    
    func testDeleteAllRows() {
        guard let sqlite = SQLiteTests.sqlite else { return }
        try? sqlite.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
        let sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString"])
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString"])
        
        var rowCount = try? sqlite.getRowCount(in: SQLiteTests.testTable)
        XCTAssertEqual(rowCount!, 2)
        
        try? sqlite.deleteAllRows(in: SQLiteTests.testTable)
        
        rowCount = try? sqlite.getRowCount(in: SQLiteTests.testTable)
        XCTAssertEqual(rowCount!, 0)
    }
    
    func testDeleteAllRows_whenResetAutoincrementIsTrue() {
        guard let sqlite = SQLiteTests.sqlite else { return }
        try? sqlite.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
        let sqlStatementInsert = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? sqlite.insertRow(sql: sqlStatementInsert, params: ["searchId", 1, "jsonString"])
        var _ = try? sqlite.insertRow(sql: sqlStatementInsert, params: ["searchId", 1, "jsonString"])
        XCTAssertEqual(sqlite.lastInsertID, 2)
        
        let sqlStatementSelect = "SELECT SEQ from sqlite_sequence WHERE name='\(SQLiteTests.testTable.name)'"
        var seq = try? sqlite.getRowCountWithCondition(sql: sqlStatementSelect)
        XCTAssertEqual(seq!, 2)
        
        try? sqlite.deleteAllRows(in: SQLiteTests.testTable, resetAutoincrement: true) // resetAutoincrement = true by default
        
        seq = try? sqlite.getRowCountWithCondition(sql: sqlStatementSelect)
        XCTAssertEqual(seq!, 0)
        
        let _ = try? sqlite.insertRow(sql: sqlStatementInsert, params: ["searchId", 1, "jsonString"])
        XCTAssertEqual(sqlite.lastInsertID, 1)
        
        seq = try? sqlite.getRowCountWithCondition(sql: sqlStatementSelect)
        XCTAssertEqual(seq!, 1)
    }
    
    func testDeleteAllRows_whenResetAutoincrementIsFalse() {
        guard let sqlite = SQLiteTests.sqlite else { return }
        try? sqlite.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
        let sqlStatementInsert = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? sqlite.insertRow(sql: sqlStatementInsert, params: ["searchId", 1, "jsonString"])
        var _ = try? sqlite.insertRow(sql: sqlStatementInsert, params: ["searchId", 1, "jsonString"])
        XCTAssertEqual(sqlite.lastInsertID, 2)
        
        let sqlStatementSelect = "SELECT SEQ from sqlite_sequence WHERE name='\(SQLiteTests.testTable.name)'"
        var seq = try? sqlite.getRowCountWithCondition(sql: sqlStatementSelect)
        XCTAssertEqual(seq!, 2)
        
        try? sqlite.deleteAllRows(in: SQLiteTests.testTable, resetAutoincrement: false)
        
        seq = try? sqlite.getRowCountWithCondition(sql: sqlStatementSelect)
        XCTAssertEqual(seq!, 2)
        
        let _ = try? sqlite.insertRow(sql: sqlStatementInsert, params: ["searchId", 1, "jsonString"])
        XCTAssertEqual(sqlite.lastInsertID, 3)
        
        seq = try? sqlite.getRowCountWithCondition(sql: sqlStatementSelect)
        XCTAssertEqual(seq!, 3)
    }
    
    func testGetRowCount() {
        guard let sqlite = SQLiteTests.sqlite else { return }
        try? sqlite.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
        let sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString"])
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString"])
        
        let rowCount = try? sqlite.getRowCount(in: SQLiteTests.testTable)
        XCTAssertEqual(rowCount!, 2)
    }
    
    func testGetRowCountWithCondition() {
        guard let sqlite = SQLiteTests.sqlite else { return }
        try? sqlite.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
        var sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString_1"])
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId", 2, "jsonString_2"])
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId_1", 1, "jsonString_3"])
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId_1", 2, "jsonString_4"])
                
        sqlStatement = "SELECT COUNT(*) FROM \(SQLiteTests.testTable.name) WHERE searchId = ?;"
        let rowCount = try? sqlite.getRowCountWithCondition(sql: sqlStatement, params: ["searchId_1"])
        XCTAssertEqual(rowCount!, 2)
    }
    
    func testGetRowCountWithCondition_whenInvalidCondition() {
        guard let sqlite = SQLiteTests.sqlite else { return }
        try? sqlite.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
        var sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString_1"])
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId_1", 1, "jsonString_2"])
        
        sqlStatement = "SELECT COUNT(*) FROM \(SQLiteTests.testTable.name) WHERE searchId = ?;"
        let rowCount = try? sqlite.getRowCountWithCondition(sql: sqlStatement, params: ["searchId_2"])
        XCTAssertEqual(rowCount!, 0)
    }
    
    func testGetRow_whenOrderIsASC() {
        guard let sqlite = SQLiteTests.sqlite else { return }
        try? sqlite.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
        var sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString_1"])
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId", 2, "jsonString_2"])
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId_1", 1, "jsonString_3"])
        
        sqlStatement = "SELECT * FROM \(SQLiteTests.testTable.name) WHERE searchId = ? ORDER BY sortId ASC;"
        
        let rows = try? sqlite.getRow(from: SQLiteTests.testTable, sql: sqlStatement, params: ["searchId"])
        XCTAssertEqual(rows!.count, 2)
        
        let firstRow = rows![0]
        XCTAssertEqual(firstRow.count, 4)
        XCTAssertEqual(firstRow[0].value as! Int, 1) // "id" INTEGER NOT NULL
        XCTAssertEqual(firstRow[1].value as! String, "searchId") // "searchId" CHAR(255) NOT NULL
        XCTAssertEqual(firstRow[2].value as! Int, 1) // "sortId" INT NOT NULL
        XCTAssertEqual(firstRow[3].value as! String, "jsonString_1") // "json" TEXT NOT NULL
    }
    
    func testGetRow_whenOrderIsDESC() {
        guard let sqlite = SQLiteTests.sqlite else { return }
        try? sqlite.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
        var sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString_1"])
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId", 2, "jsonString_2"])
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId_1", 1, "jsonString_3"])
        
        sqlStatement = "SELECT * FROM \(SQLiteTests.testTable.name) WHERE searchId = ? ORDER BY sortId DESC;"
        
        let rows = try? sqlite.getRow(from: SQLiteTests.testTable, sql: sqlStatement, params: ["searchId"])
        XCTAssertEqual(rows!.count, 2)
        
        let firstRow = rows![0]
        XCTAssertEqual(firstRow.count, 4)
        XCTAssertEqual(firstRow[0].value as! Int, 2) // "id" INTEGER NOT NULL
        XCTAssertEqual(firstRow[1].value as! String, "searchId") // "searchId" CHAR(255) NOT NULL
        XCTAssertEqual(firstRow[2].value as! Int, 2) // "sortId" INT NOT NULL
        XCTAssertEqual(firstRow[3].value as! String, "jsonString_2") // "json" TEXT NOT NULL
    }
    
    func testGetRow_whenReturnValueIsNULL() {
        guard let sqlite = SQLiteTests.sqlite else { return }
        
        // TestTable2
        try? sqlite.createTable(sql: SQLiteTests.sqlCreateTestTable2)
        
        var sqlStatement = "INSERT INTO \(SQLiteTests.testTable2.name) (updated) VALUES (?);" // Without specifying a value, jsonData will be NULL
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: [Date()])
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: [Date()])
        
        sqlStatement = "SELECT * FROM \(SQLiteTests.testTable2.name) WHERE isDeleted = ?"
        var rows = try? sqlite.getRow(from: SQLiteTests.testTable2, sql: sqlStatement, params: [false])
        XCTAssertEqual(rows!.count, 2)
        var firstRow = rows!.first
        XCTAssertEqual(firstRow!.count, 4)
        XCTAssertEqual(firstRow![0].value as! Int, 1) // "rowid" INTEGER NOT NULL
        XCTAssertEqual(firstRow![1].value as? Data, nil) // "jsonData" BLOB NULL
        XCTAssertEqual(firstRow![2].value as! Bool, false) // "isDeleted" BOOLEAN DEFAULT 0 NOT NULL
        XCTAssertTrue((firstRow![3].value as! Date) <= Date()) // "updated" DATETIME NOT NULL
        
        // TestTable3
        try? sqlite.createTable(sql: SQLiteTests.sqlCreateTestTable3)
        
        sqlStatement = "INSERT INTO \(SQLiteTests.testTable3.name) (id) VALUES (?);" // id will be autoincremented, all nullable values will be NULL
        let _ = try? sqlite.insertRow(sql: sqlStatement)
        let _ = try? sqlite.insertRow(sql: sqlStatement)
        
        rows = try? sqlite.getAllRows(from: SQLiteTests.testTable3)
        XCTAssertEqual(rows!.count, 2)
        firstRow = rows!.first
        XCTAssertEqual(firstRow!.count, 7)
        XCTAssertEqual(firstRow![0].value as! Int, 1) // "id" INTEGER NOT NULL
        XCTAssertEqual(firstRow![1].value as? Int, nil) // "intValue" INTEGER NULL
        XCTAssertEqual(firstRow![2].value as? Bool, nil) // "boolValue" BOOLEAN NULL
        XCTAssertEqual(firstRow![3].value as? String, nil) // "textColumn" TEXT NULL
        XCTAssertEqual(firstRow![4].value as? Double, nil) // "realColumn" DOUBLE NULL
        XCTAssertEqual(firstRow![5].value as? Data, nil) // "blobColumn" BLOB NULL
        XCTAssertEqual(firstRow![6].value as? Date, nil) // "dateColumn" DATETIME NULL
    }
    
    func testGetRow_whenSpecifyingSpecificColumns() {
        guard let sqlite = SQLiteTests.sqlite else { return }
        try? sqlite.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
        var sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString_1"])
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId", 2, "jsonString_2"])
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId_1", 1, "jsonString_3"])
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId_1", 2, "jsonString_4"])
        
        sqlStatement = "SELECT id, sortId, json FROM \(SQLiteTests.testTable.name) WHERE searchId = ?;"
        let rows = try? sqlite.getRow(from: SQLiteTests.testTable, sql: sqlStatement, params: ["searchId"])
        XCTAssertEqual(rows!.count, 2)
        
        let firstRow = rows![0]
        XCTAssertEqual(firstRow.count, 3) // even though testTable contains 4 columns, the resulting table of this query contains 3 columns (without searchId)
        XCTAssertEqual(firstRow[0].value as! Int, 1) // "id" INTEGER NOT NULL
        XCTAssertEqual(firstRow[1].value as! Int, 1) // "sortId" INT NOT NULL
        XCTAssertEqual(firstRow[2].value as! String, "jsonString_1") // "json" TEXT NOT NULL
    }
    
    func testGetRow_whenInvalidCondition() {
        guard let sqlite = SQLiteTests.sqlite else { return }
        try? sqlite.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
        var sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString_1"])
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId", 2, "jsonString_2"])
        
        sqlStatement = "SELECT * FROM \(SQLiteTests.testTable.name) WHERE searchId = ?;"
        let rows = try? sqlite.getRow(from: SQLiteTests.testTable, sql: sqlStatement, params: ["someId"])
        XCTAssertEqual(rows!.count, 0)
    }
    
    func testGetAllRows() {
        guard let sqlite = SQLiteTests.sqlite else { return }
        try? sqlite.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
        let sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString_1"])
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId", 2, "jsonString_2"])
        
        let rows = try? sqlite.getAllRows(from: SQLiteTests.testTable)
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
        guard let sqlite = SQLiteTests.sqlite else { return }
        
        // TestTable
        try? sqlite.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
        var sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString_1"])
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId", 2, "jsonString_2"])
        
        var row = try? sqlite.getByID(from: SQLiteTests.testTable, id: 1)
        XCTAssertEqual(row!.count, 4)
        XCTAssertEqual(row![0].value as! Int, 1) // "id" INTEGER NOT NULL
        XCTAssertEqual(row![1].value as! String, "searchId") // "searchId" CHAR(255) NOT NULL
        XCTAssertEqual(row![2].value as! Int, 1) // "sortId" INT NOT NULL
        XCTAssertEqual(row![3].value as! String, "jsonString_1") // "json" TEXT NOT NULL
        
        // TestTable2
        try? sqlite.createTable(sql: SQLiteTests.sqlCreateTestTable2)
        
        sqlStatement = "INSERT INTO \(SQLiteTests.testTable2.name) (jsonData, updated) VALUES (?, ?);"
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["jsonString_1".data(using: .utf8)!, Date()])
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["jsonString_2".data(using: .utf8)!, Date()])
        
        row = try? sqlite.getByID(from: SQLiteTests.testTable2, id: 2)
        XCTAssertEqual(row!.count, 4)
        XCTAssertEqual(row![0].value as! Int, 2) // "rowid" INTEGER NOT NULL
        XCTAssertEqual(String(data: (row![1].value as! Data), encoding: .utf8), "jsonString_2") // "jsonData" BLOB NULL
        XCTAssertEqual(row![2].value as! Bool, false) // "isDeleted" BOOLEAN DEFAULT 0 NOT NULL
        XCTAssertTrue((row![3].value as! Date) <= Date()) // "updated" DATETIME NOT NULL
    }
    
    func testGetByID_whenInvalidId() {
        guard let sqlite = SQLiteTests.sqlite else { return }
        try? sqlite.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
        let sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString_1"])
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId", 2, "jsonString_2"])
        
        let row = try? sqlite.getByID(from: SQLiteTests.testTable, id: 3)
        XCTAssertNil(row)
    }
    
    func testGetByID_whenUsingDate() {
        guard let sqlite = SQLiteTests.sqlite else { return }
        try? sqlite.createTable(sql: SQLiteTests.sqlCreateTestTable3)
        
        // Insert in date format
        let sqlStatement = "INSERT INTO \(SQLiteTests.testTable3.name) (dateColumn) VALUES (?);"
        let nowDate = Date()
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: [nowDate])
        
        let lastInsertId = sqlite.lastInsertID // should be 1
        let row = try? sqlite.getByID(from: SQLiteTests.testTable3, id: lastInsertId)
        XCTAssertEqual(row!.count, SQLiteTests.testTable3.columns.count) // should be 7
        XCTAssertEqual(row![0].value as! Int, lastInsertId) // "id" INTEGER NOT NULL
        XCTAssertEqual((row![6].value as! Date).description, nowDate.description) // "dateColumn" DATETIME NULL
    }
    
    func testGetByID_whenUsingTimeInterval() {
        guard let sqlite = SQLiteTests.sqlite else { return }
        try? sqlite.createTable(sql: SQLiteTests.sqlCreateTestTable3)
        
        // Insert in time interval format
        let sqlStatement = "INSERT INTO \(SQLiteTests.testTable3.name) (dateColumn) VALUES (?);"
        let secondsStamp = Int(Date().timeIntervalSince1970)
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: [secondsStamp])
        
        let lastInsertId = sqlite.lastInsertID // should be 1
        let row = try? sqlite.getByID(from: SQLiteTests.testTable3, id: lastInsertId)
        XCTAssertEqual(row!.count, SQLiteTests.testTable3.columns.count) // should be 7
        XCTAssertEqual(row![0].value as! Int, lastInsertId) // "id" INTEGER NOT NULL
        XCTAssertEqual(Int((row![6].value as! Date).timeIntervalSince1970), secondsStamp) // "dateColumn" DATETIME NULL
    }
    
    func testGetLastRow() {
        guard let sqlite = SQLiteTests.sqlite else { return }
        try? sqlite.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
        let sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString_1"])
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId", 2, "jsonString_2"])
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId", 3, "jsonString_3"])
        
        let row = try? sqlite.getLastRow(from: SQLiteTests.testTable)
        XCTAssertEqual(row!.count, 4)
        XCTAssertEqual(row![0].value as! Int, 3) // "id" INTEGER NOT NULL
        XCTAssertEqual(row![1].value as! String, "searchId") // "searchId" CHAR(255) NOT NULL
        XCTAssertEqual(row![2].value as! Int, 3) // "sortId" INT NOT NULL
        XCTAssertEqual(row![3].value as! String, "jsonString_3") // "json" TEXT NOT NULL
    }
    
    func testGetLastInsertId() {
        guard let sqlite = SQLiteTests.sqlite else { return }
        try? sqlite.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
        let sqlStatement = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString"])
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString"])
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString"])
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString"])
        let returnedLastId = try? sqlite.insertRow(sql: sqlStatement, params: ["searchId", 1, "jsonString"])
        
        let lastInsertId = sqlite.lastInsertID
        XCTAssertEqual(lastInsertId, 5)
        XCTAssertEqual(returnedLastId, lastInsertId)
    }
    
    func testGetChangesAndGetTotalChanges() {
        guard let sqlite = SQLiteTests.sqlite else { return }
        try? sqlite.createTable(sql: SQLiteTests.sqlCreateTestTable2)
        
        var sqlStatement = "INSERT INTO \(SQLiteTests.testTable2.name) (jsonData, updated) VALUES (?, ?);"
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["jsonString_1".data(using: .utf8)!, Date()])
        let _ = try? sqlite.insertRow(sql: sqlStatement, params: ["jsonString_2".data(using: .utf8)!, Date()])
        
        sqlStatement = "UPDATE \(SQLiteTests.testTable2.name) SET isDeleted = ?, updated = ?"
        try? sqlite.updateRow(sql: sqlStatement, params: [true, Date()])
        
        XCTAssertEqual(sqlite.changes, 2)
        XCTAssertTrue(sqlite.totalChanges >= 4)
    }
    
    func testQuery() {
        guard let sqlite = SQLiteTests.sqlite else { return }
        try? sqlite.createTable(sql: SQLiteTests.sqlCreateTestTable)
        
        let sqlStatementUpdate = "UPDATE sqlite_sequence SET SEQ=9 WHERE name='\(SQLiteTests.testTable.name)';"
        try? sqlite.query(sql: sqlStatementUpdate)
        
        let sqlStatementInsert = "INSERT INTO \(SQLiteTests.testTable.name) (searchId, sortId, json) VALUES (?, ?, ?);"
        let lastInsertId = try? sqlite.insertRow(sql: sqlStatementInsert, params: ["searchId", 1, "jsonString"])
        XCTAssertEqual(lastInsertId, 10)
        
        let sqlStatementSelect = "SELECT SEQ FROM sqlite_sequence WHERE name='\(SQLiteTests.testTable.name)'"
        let seq = try? sqlite.getRowCountWithCondition(sql: sqlStatementSelect)
        XCTAssertEqual(seq!, 10)
    }
}


