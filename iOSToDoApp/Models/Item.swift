//
//  Item.swift
//  iOSToDoApp
//
//  Created by CMR on 20/09/2018.
//

import RealmSwift

class Item: Object {
    @objc dynamic var itemId: String = UUID().uuidString
    @objc dynamic var body: String = ""
    @objc dynamic var isDone: Bool = false
    @objc dynamic var timestamp: Date = Date()
    
    override static func primaryKey() -> String? {
        return "itemId"
    }
}
