//
//  ChiffRequestsLogStorage.swift
//
//
//  Created by Dmitriy Starodubtsev on 27.07.2021.
//

import Foundation

public class ChiffRequestsLogStorage: NSObject {
    
    public static let sharedStorage = ChiffRequestsLogStorage()
    private var logs: [ChiffRequestLogModel]?

    public func updateLogWithDeclineFor(browserTab: Int) {
        try? loadLogs()
        if var logModel = logs?.filter({ $0.browserTab == browserTab}).first  {
            logModel.isRejected = true
            save(log: logModel)
        }
    }
    
    public func save(log: ChiffRequestLogModel) {
        do {
            if let logModel = logs?.filter({ $0.browserTab == log.browserTab}).first  {
                var tmpArray:[ChiffRequestLogModel] = logs!
                tmpArray.remove(at: (tmpArray.firstIndex(of: logModel))!)
                logs = tmpArray
            }
            self.logs?.append(log)
            
            let logData = try PropertyListEncoder().encode(logs)
            try logData.write(to: Self.path)
        } catch {
            Logger.shared.warning("Failed to write device logging.", error: error)
        }
    }

    public func getLogForSession(id: String) throws -> [ChiffRequestLogModel] {
        try loadLogs()
        return logs?.filter { $0.sessionId == id } ?? []
    }
    
    private func loadLogs() throws {
        guard logs == nil else {
            return
        }
        guard let data = try? Data(contentsOf: Self.path, options: .alwaysMapped) else {
            logs = []
            return
        }
        logs = try PropertyListDecoder().decode([ChiffRequestLogModel].self, from: data)
    }

    private static let fileName = "RequestsData.log"
    private static let path = URL(fileURLWithPath: ChiffRequestsLogStorage.fileName, relativeTo: getDocumentsDirectory())
    
    static private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

}
