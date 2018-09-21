//
//  Project.swift
//  iOSToDoApp
//
//  Created by CMR on 20/09/2018.
//

import RealmSwift

class Project: Object {
    @objc dynamic var projectId: String = UUID().uuidString
//    @objc dynamic var owner: String = ""
    @objc dynamic var name: String = ""
    @objc dynamic var timestamp: Date = Date()
    
    let items = List<Item>()
    let permissions = List<Permission>()
    
    override static func primaryKey() -> String? {
        return "projectId"
    }
}
