import Foundation

public protocol ReadableDataStorage {
    func fetchValue(for key: String) throws -> Data
    func fetchValue(for key: String, handler: @escaping (Result<Data, Error>) -> Void)
}

public protocol WritableDataStorage {
    func save(value: Data, for key: String) throws
    func save(value: Data, for key: String, handler: @escaping (Result<Data, Error>) -> Void)
}

public typealias DataStorage = ReadableDataStorage & WritableDataStorage

public final class DefaultDataStorage {
    let path : URL
    let queue : DispatchQueue
    let fileManager : FileManager
    
    public init(path: URL, queue: DispatchQueue = .init(label: "DiskCache.Queue"), fileManager: FileManager = .default) {
        self.path = path
        self.queue = queue
        self.fileManager = fileManager
    }
}

extension DefaultDataStorage : WritableDataStorage {
    public func save(value: Data, for key: String) throws {
        let url = path.appendingPathComponent(key)
        do {
            try self.createFolders(in: url)
            try value.write(to: url, options: .atomic)
        } catch {
            throw StorageError.cantWrite(error)
        }
    }
    
    public func save(value: Data, for key: String, handler: @escaping (Result<Data, Error>) -> Void) {
        queue.async {
            do {
                try self.save(value: value, for: key)
                handler(.success(value))
            } catch {
                handler(.failure(error))
            }
        }
    }
}

extension DefaultDataStorage : ReadableDataStorage {
    public func fetchValue(for key: String) throws -> Data {
        let url = path.appendingPathComponent(key)
        guard let data = fileManager.contents(atPath: url.path) else {
            throw StorageError.notFound
        }
        return data
    }
    
    public func fetchValue(for key: String, handler: @escaping (Result<Data, Error>) -> Void) {
        queue.async {
            handler(Result { try self.fetchValue(for: key) })
        }
    }
}

// helper methods

extension DefaultDataStorage {
    private func createFolders(in url: URL) throws {
        let folderUrl = url.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: folderUrl.path) {
            try fileManager.createDirectory(
                at: folderUrl,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }
}
