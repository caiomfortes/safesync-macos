//
//  BookmarkManager.swift
//  SafeSync2
//
//  Created by Caio Gabriel de Moura Fortes on 07/04/26.
//

import Foundation

enum BookmarkError: Error, LocalizedError {
    case couldNotCreate(underlying: Error)
    case couldNotResolve(underlying: Error)
    case accessDenied(URL)
    
    var errorDescription: String? {
        switch self {
        case .couldNotCreate(let error):
            return "Não foi possível criar o bookmark: \(error.localizedDescription)"
        case .couldNotResolve(let error):
            return "Não foi possível resolver o bookmark: \(error.localizedDescription)"
        case .accessDenied(let url):
            return "Acesso negado à pasta: \(url.path)"
        }
    }
}

enum BookmarkManager {
    
    static func createBookmark(for url: URL) throws -> Data {
        do {
            return try url.bookmarkData(
                options: [.withSecurityScope],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
        } catch {
            throw BookmarkError.couldNotCreate(underlying: error)
        }
    }
    
    static func resolveBookmark(_ data: Data) throws -> (url: URL, isStale: Bool) {
        var isStale = false
        do {
            let url = try URL(
                resolvingBookmarkData: data,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            return (url, isStale)
        } catch {
            throw BookmarkError.couldNotResolve(underlying: error)
        }
    }
    
    static func withAccess<T>(to url: URL, perform block: () throws -> T) throws -> T {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        guard accessing else {
            throw BookmarkError.accessDenied(url)
        }
        
        return try block()
    }
}
