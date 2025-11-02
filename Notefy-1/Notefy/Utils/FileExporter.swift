import Foundation
import UIKit

class FileExporter {
    
    static func export(note: Note) -> URL? {
        let text = "\(note.title)\n\n\(note.content)"
        let fileName = "\(note.title).txt"
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        
        guard let fileURL = documentDirectory?.appendingPathComponent(fileName) else {
            return nil
        }
        
        do {
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error writing file: \(error)")
            return nil
        }
    }
    
    static func share(note: Note, from viewController: UIViewController) {
        guard let fileURL = export(note: note) else { return }
        
        let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        viewController.present(activityViewController, animated: true, completion: nil)
    }
}