//
//  ChiffRequestsLogStorage.swift
//
//
//  Created by Dmitriy Starodubtsev on 27.07.2021.
//

import Foundation

public class ChiffRequestsLogStorage: NSObject {
    
    public static let sharedStorage = ChiffRequestsLogStorage()
    
    public func updateLogWithDeclineFor(browserTab: Int) {
        let _ = getLogs()
        if var logModel = ChiffRequestsLogStorage.logsArray?.filter({ model in model.browserTab == browserTab}).first  {
            logModel.isRejected = true
            save(log: logModel)
        }
    }
    
    public func save(log: ChiffRequestLogModel) {
        do {
            if ChiffRequestsLogStorage.logsArray == nil {
                ChiffRequestsLogStorage.logsArray = [ChiffRequestLogModel]()
            }
            if let logModel = ChiffRequestsLogStorage.logsArray?.filter({ model in model.browserTab == log.browserTab}).first  {
                var tmpArray:[ChiffRequestLogModel] = ChiffRequestsLogStorage.logsArray!
                tmpArray.remove(at: (tmpArray.firstIndex(of: logModel))!)
                ChiffRequestsLogStorage.logsArray = tmpArray
            }
            ChiffRequestsLogStorage.logsArray?.append(log)
            
            let logData = try PropertyListEncoder().encode(ChiffRequestsLogStorage.logsArray!)
            try logData.write(to: ChiffRequestsLogStorage.path)
            ChiffRequestsLogStorage.logsArray = nil
        } catch {
            print("Couldn't write file")
        }
    }

    public func getLogForSession(ID: String) -> [ChiffRequestLogModel]? {
        try? getLogFor(ID: ID)
    }
    
    private func getLogFor(ID: String) throws -> [ChiffRequestLogModel] {
        guard ChiffRequestsLogStorage.logsArray == nil else {
            return ChiffRequestsLogStorage.logsArray!.filter { model in
                model.sessionID == ID
            }
        }
        
        let _ = try getLogs()
        
        return ChiffRequestsLogStorage.logsArray?.filter({ model in
            model.sessionID == ID
        }) ??  [ChiffRequestLogModel]()
        
    }
    
    private func getLogs() -> [ChiffRequestLogModel]? {
        let data = try! Data(contentsOf: ChiffRequestsLogStorage.path, options: .alwaysMapped)
        ChiffRequestsLogStorage.logsArray = try? PropertyListDecoder().decode([ChiffRequestLogModel].self, from: data)
        
        return ChiffRequestsLogStorage.logsArray
    }
    
    private static var logsArray: [ChiffRequestLogModel]?
    private static let fileName = "RequestsData.log"
    private static let path = getDocumentsDirectory().appendingPathComponent(ChiffRequestsLogStorage.fileName)
    
    static private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
