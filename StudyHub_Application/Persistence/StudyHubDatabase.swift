
import Foundation

enum StudyHubDatabase {

    static func createDirectoryIfNeeded() throws {
        let directorio = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]

        try FileManager.default.createDirectory(
            at: directorio,
            withIntermediateDirectories: true
        )
    }
}

