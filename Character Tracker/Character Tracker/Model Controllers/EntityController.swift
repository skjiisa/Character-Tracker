//
//  EntityController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 2/29/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import CoreData

//MARK: EntityController

protocol EntityController: AnyObject {
    associatedtype Entity: NamedEntity
    associatedtype Value: Hashable
    
    // Temp Entities
    
    var tempEntities: [(entity: Entity, value: Value)] { get set }
    
    func sortTempEntities()
    func add(tempEntity: Entity, value: Value)
    func remove(tempEntity: Entity)
    
    // Entity Entity CRUD
}

//MARK: EntityController default implementations

extension EntityController {
    func add(tempEntity entity: Entity, value: Value) {
        if !tempEntities.contains(where: { $0.entity == entity }) {
            tempEntities.append((entity, value))
            sortTempEntities()
        }
    }
    
    func remove(tempEntity entity: Entity) {
        tempEntities.removeAll(where: { $0.entity == entity })
    }
}

protocol NamedEntity: NSManagedObject {
    var name: String? { get set }
}

extension Ingredient: NamedEntity {}
extension Module: NamedEntity {}
extension Attribute: NamedEntity {}
extension Mod: NamedEntity {}
