//
//  File.swift
//  
//
//  Created by BJ Beecher on 7/22/21.
//

import Foundation
import Combine

public final class CodableStorage {
    public typealias Completion<T: Codable> = (Result<T, Error>) -> Void
    
    let dataStorage: DataStorage
    let decoder: JSONDecoder
    let encoder: JSONEncoder
    
    public init(dataStorage: DataStorage, decoder: JSONDecoder = .init(), encoder: JSONEncoder = .init()) {
        self.dataStorage = dataStorage
        self.decoder = decoder
        self.encoder = encoder
    }
}

public extension CodableStorage {
    func fetch<T: Decodable>(for key: String) throws -> T {
        let data = try dataStorage.fetchValue(for: key)
        return try decoder.decode(T.self, from: data)
    }
    
    func asyncFetch<T: Codable>(for key: String, completion: @escaping Completion<T>) {
        dataStorage.fetchValue(for: key) { result in
            completion(result.flatMap { data in
                do {
                    return .success(try self.decoder.decode(T.self, from: data))
                } catch {
                    return .failure(error)
                }
            })
        }
    }
    
    func fetchPublisher<T: Codable>(forKey key: String) -> AnyPublisher<T, Error> {
        Deferred {
            Future<T, Error> { promise in
                self.asyncFetch(for: key, completion: promise)
            }
        }.eraseToAnyPublisher()
    }
    
    func save<T: Encodable>(_ value: T, for key: String) throws {
        let data = try encoder.encode(value)
        try dataStorage.save(value: data, for: key)
    }
}
