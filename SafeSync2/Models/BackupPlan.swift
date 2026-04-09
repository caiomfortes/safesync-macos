import Foundation

struct BackupPlan: Identifiable, Codable {
    let id: UUID
    var name: String
    var sourceBookmarks: [Data]
    var destinationBookmark: Data
    var createdAt: Date
    var lastRunAt: Date?
    var isMirrorMode: Bool
    
<<<<<<< HEAD
    init(name: String, sourceBookmarks: [Data], destinationBookmarks: Data){
        self.id = UUID()
=======
    init(
        id: UUID = UUID(),
        name: String,
        sourceBookmarks: [Data],
        destinationBookmark: Data,
        createdAt: Date = Date(),
        lastRunAt: Date? = nil,
        isMirrorMode: Bool = false
    ) {
        self.id = id
>>>>>>> etapa2
        self.name = name
        self.sourceBookmarks = sourceBookmarks
        self.destinationBookmark = destinationBookmark
        self.createdAt = createdAt
        self.lastRunAt = lastRunAt
        self.isMirrorMode = isMirrorMode
    }
    
    // MARK: - Codable customizado para compatibilidade
    
    enum CodingKeys: String, CodingKey {
        case id, name, sourceBookmarks, destinationBookmark
        case createdAt, lastRunAt, isMirrorMode
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.sourceBookmarks = try container.decode([Data].self, forKey: .sourceBookmarks)
        self.destinationBookmark = try container.decode(Data.self, forKey: .destinationBookmark)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.lastRunAt = try container.decodeIfPresent(Date.self, forKey: .lastRunAt)
        self.isMirrorMode = try container.decodeIfPresent(Bool.self, forKey: .isMirrorMode) ?? false
    }
}

extension BackupPlan {
    
    static func create(
        name: String,
        sourceURLs: [URL],
        destinationURL: URL,
        isMirrorMode: Bool = false
    ) throws -> BackupPlan {
        let sourceBookmarks = try sourceURLs.map { url in
            try BookmarkManager.createBookmark(for: url)
        }
        let destinationBookmark = try BookmarkManager.createBookmark(for: destinationURL)
        
        return BackupPlan(
            name: name,
            sourceBookmarks: sourceBookmarks,
            destinationBookmark: destinationBookmark,
            isMirrorMode: isMirrorMode
        )
    }
    
    struct ResolvedPlan {
        let sourceURLs: [URL]
        let destinationURL: URL
        let staleBookmarksDetected: Bool
    }
    
    func resolve() throws -> ResolvedPlan {
        var staleDetected = false
        
        let sourceURLs = try sourceBookmarks.map { data -> URL in
            let (url, isStale) = try BookmarkManager.resolveBookmark(data)
            if isStale { staleDetected = true }
            return url
        }
        
        let (destinationURL, destStale) = try BookmarkManager.resolveBookmark(destinationBookmark)
        if destStale { staleDetected = true }
        
        return ResolvedPlan(
            sourceURLs: sourceURLs,
            destinationURL: destinationURL,
            staleBookmarksDetected: staleDetected
        )
    }
}

extension BackupPlan {
    
    func withUpdatedBookmarks(
        sourceBookmarks: [Data],
        destinationBookmark: Data
    ) -> BackupPlan {
        BackupPlan(
            id: self.id,
            name: self.name,
            sourceBookmarks: sourceBookmarks,
            destinationBookmark: destinationBookmark,
            createdAt: self.createdAt,
            lastRunAt: self.lastRunAt,
            isMirrorMode: self.isMirrorMode
        )
    }
    
    func withUpdatedName(_ newName: String) -> BackupPlan {
        BackupPlan(
            id: self.id,
            name: newName,
            sourceBookmarks: self.sourceBookmarks,
            destinationBookmark: self.destinationBookmark,
            createdAt: self.createdAt,
            lastRunAt: self.lastRunAt,
            isMirrorMode: self.isMirrorMode
        )
    }
    
    func withLastRun(_ date: Date) -> BackupPlan {
        BackupPlan(
            id: self.id,
            name: self.name,
            sourceBookmarks: self.sourceBookmarks,
            destinationBookmark: self.destinationBookmark,
            createdAt: self.createdAt,
            lastRunAt: date,
            isMirrorMode: self.isMirrorMode
        )
    }
}
