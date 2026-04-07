//
//  BookmarkManager.swift
//  SafeSync2
//
//  Created by Caio Gabriel de Moura Fortes on 07/04/26.
//

import Foundation

enum BookmarkError: Error{
    case coldNotCreate
    case coldNotResolve
    case accessDenied
}


enum BookmarkManager {
    static func createBookmark(for url: URL) throws -> Data{
        do{
            return try url.bookmarkData(
                options: [.withSecurityScope],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            
        } catch{
            throw BookmarkError.coldNotCreate
        }
    }
    
    static func resolveBookmark(_ data: Data) throws -> URL{
        var isStale = false
        do{
            let url = try URL(
                resolvingBookmarkData: data,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            return url
        } catch {
            throw BookmarkError.coldNotResolve
        }
    }
}
