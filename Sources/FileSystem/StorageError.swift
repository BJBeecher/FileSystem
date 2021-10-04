//
//  File.swift
//  
//
//  Created by BJ Beecher on 7/22/21.
//

import Foundation

enum StorageError: Error {
    case notFound
    case cantWrite(Error)
}
