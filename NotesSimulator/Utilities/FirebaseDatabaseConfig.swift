import FirebaseCore
import FirebaseDatabase
import Foundation

enum FirebaseDatabaseConfig {
    private static var configuredDatabase: Database?

    static var databaseURLString: String? {
        guard let url = Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let urlString = plist["DATABASE_URL"] as? String,
              !urlString.isEmpty else {
            return nil
        }
        return urlString
    }

    static func database() -> Database? {
        guard FirebaseApp.app() != nil else { return nil }
        if let configuredDatabase {
            return configuredDatabase
        }
        let database: Database
        if let urlString = databaseURLString {
            database = Database.database(url: urlString)
        } else {
            database = Database.database()
        }
        database.isPersistenceEnabled = false
        configuredDatabase = database
        return database
    }

    static func reference() -> DatabaseReference? {
        database()?.reference()
    }
}
