//
//  Untitled.swift
//  EssentialFeed
//
//  Created by 2674143 on 14/09/25.
//

import CoreData

@objc(ManagedFeedImage)
 class ManagedFeedImage: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var imageDescription: String?
    @NSManaged var location: String?
    @NSManaged var url: URL
    @NSManaged var cache: ManagedCache
}

extension ManagedFeedImage {
    
     var local: LocalFeedImage {
        return LocalFeedImage(id: self.id, description: self.imageDescription, location: self.location, url: self.url)
    }
    
     static func images(_ localFeedImage: [LocalFeedImage], context: NSManagedObjectContext) -> NSOrderedSet {
        return NSOrderedSet(array: localFeedImage.map { local in
            let managed = ManagedFeedImage(context: context)
            managed.id = local.id
            managed.imageDescription = local.description
            managed.location = local.location
            managed.url = local.url
            return managed
        })
    }
    
}
