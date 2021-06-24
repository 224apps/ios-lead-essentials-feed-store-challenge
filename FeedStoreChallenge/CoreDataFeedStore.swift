//
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import CoreData

public final class CoreDataFeedStore: FeedStore {
	private static let modelName = "FeedStore"
	private static let model = NSManagedObjectModel(name: modelName, in: Bundle(for: CoreDataFeedStore.self))

	private let container: NSPersistentContainer
	private let context: NSManagedObjectContext

	struct ModelNotFound: Error {
		let modelName: String
	}

	public init(storeURL: URL) throws {
		guard let model = CoreDataFeedStore.model else {
			throw ModelNotFound(modelName: CoreDataFeedStore.modelName)
		}

		container = try NSPersistentContainer.load(
			name: CoreDataFeedStore.modelName,
			model: model,
			url: storeURL
		)
		context = container.newBackgroundContext()
	}

	public func retrieve(completion: @escaping RetrievalCompletion) {
		let context = self.context
		context.perform {
			do {
				let request = NSFetchRequest<ManagedCache>(entityName: ManagedCache.entity().name!)
				request.returnsObjectsAsFaults = false
				if let cache = try context.fetch(request).first {
					let feed = cache.feed
						.compactMap { $0 as? ManagedFeedImage }
						.map { LocalFeedImage(id: $0.id, description: $0.imageDescription, location: $0.location, url: $0.url) }
					completion(.found(feed: feed, timestamp: cache.timestamp))
				} else {
					completion(.empty)
				}
			} catch {
				completion(.failure(error))
			}
		}
	}

	public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
		let context = self.context
		context.perform {
			let newCache = ManagedCache(context: context)

			newCache.feed = NSOrderedSet(array: feed.map { feed in
				let managedFeedImage = ManagedFeedImage(context: context)
				managedFeedImage.id = feed.id
				managedFeedImage.imageDescription = feed.description
				managedFeedImage.location = feed.location
				managedFeedImage.url = feed.url
				return managedFeedImage
			})
			newCache.timestamp = timestamp

			try! context.save()
			completion(nil)
		}
	}

	public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
		fatalError("Must be implemented")
	}
}
