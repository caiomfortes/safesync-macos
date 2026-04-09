//
//  HelpView.swift
//  SafeSync2
//
//  Created by Caio Gabriel de Moura Fortes on 09/04/26.
//


import SwiftUI

struct HelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSpacing.xl) {
                header
                
                section(
                    icon: "info.circle",
                    title: "What is SafeSync?",
                    body: "SafeSync is an incremental backup tool for macOS. It copies files from your source folders to a destination, only transferring what's new or changed. It's designed to be safe, predictable, and easy to use."
                )
                
                section(
                    icon: "square.on.square",
                    title: "Backup vs. Sync",
                    body: "**Backup mode** copies new and updated files to the destination. It never removes anything from the destination, even if you delete files from the source. This is the safest option for protecting your data.\n\n**Sync mode** mirrors your source to the destination. Files that exist in the destination but not in the source are moved to the Trash. Use this when you want the destination to exactly match the source."
                )
                
                section(
                    icon: "plus.rectangle",
                    title: "Creating a plan",
                    body: "Click the **+** button in the sidebar to create a new plan. Choose between Backup or Sync mode, then add one or more source folders and a destination folder. Give your plan a name and click Create."
                )
                
                section(
                    icon: "play.circle",
                    title: "Running a backup",
                    body: "Select a plan from the sidebar and click **Start backup**. SafeSync will analyze your folders and show you a preview of what will be copied (and, in Sync mode, what will be removed). Review the summary and click Confirm to proceed."
                )
                
                section(
                    icon: "shield.checkered",
                    title: "Safety features",
                    body: "SafeSync is designed to never lose your data:\n\n• Files are copied atomically — if something fails midway, your destination files stay intact.\n• Sync mode moves files to the Trash, not permanent deletion. You can recover them.\n• Symbolic links are ignored to prevent unexpected file traversal.\n• Hidden files and system files are excluded by default.\n• When the source appears empty (possibly due to an error), Sync operations are cancelled to prevent accidental data loss."
                )
                
                section(
                    icon: "questionmark.circle",
                    title: "Frequently asked questions",
                    body: "**Why is my backup so fast?**\nIf source and destination are on the same APFS volume, macOS uses clones — files don't actually duplicate. This is fast but doesn't protect against disk failure. For real backups, use an external drive.\n\n**Can I run multiple backups at once?**\nYes, up to 3 simultaneously. Additional plans wait in queue.\n\n**What happens if I close the app during a backup?**\nThe app continues running in the menu bar. Backups complete in the background.\n\n**Can I cancel a backup?**\nYes, click the X next to it in the menu bar status, or in the app itself. Files already copied stay where they are."
                )
            }
            .padding(DesignSpacing.xl)
        }
        .frame(minWidth: 600, idealWidth: 700, minHeight: 500, idealHeight: 700)
        .background(Color.dsSurfaceSecondary)
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.sm) {
            HStack(spacing: DesignSpacing.md) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(Color.dsAccent)
                
                Text("SafeSync Help")
                    .font(DesignFont.largeTitle)
                    .foregroundStyle(Color.dsTextPrimary)
            }
            
            Text("Everything you need to know to get started.")
                .font(DesignFont.body)
                .foregroundStyle(Color.dsTextSecondary)
        }
    }
    
    private func section(icon: String, title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: DesignSpacing.md) {
            HStack(spacing: DesignSpacing.sm) {
                Image(systemName: icon)
                    .foregroundStyle(Color.dsAccent)
                Text(title)
                    .font(DesignFont.headline)
                    .foregroundStyle(Color.dsTextPrimary)
            }
            
            Text(.init(body))
                .font(DesignFont.body)
                .foregroundStyle(Color.dsTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

#Preview {
    HelpView()
}