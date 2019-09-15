//
//  SelfieStore.swift
//  Selfiegram
//
//  Created by Mike Liao on 2019/9/8.
//  Copyright © 2019 Mike Liao. All rights reserved.
//

import Foundation
import UIKit.UIImage

class Selfie: Codable {
    let created: Date
    let id: UUID
    var title = "New Selfie!"
    
    // computed variables
    var image: UIImage? {
        get {
            return SelfieStore.shared.getImage(id: self.id)
        }
        set {
            // try? or try! is used when a function could throw error
            try? SelfieStore.shared.setImage(id: self.id, image: newValue)
        }
    }
    
    init(title: String) {
        self.title = title
        self.created = Date()
        self.id = UUID()
    }
}

// SelfieStore cannot be subclassed
final class SelfieStore {
    static let shared = SelfieStore()
    
    // declare a dictionary to hold id and image pair
    private var imageCache: [UUID: UIImage] = [:]
    
    var documentFolder: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask).first!
    }
    
    func getImage(id: UUID) -> UIImage? {
        if let image = imageCache[id] {
            return image
        }
        
        let imageURL = documentFolder.appendingPathComponent("\(id.uuidString)-image.jpg")
        
        guard let imageData = try? Data(contentsOf: imageURL) else {
            // must return the function when guard test fails
            return nil
        }
        
        guard let image = UIImage(data: imageData) else {
            return nil
        }
        
        imageCache[id] = image
        return image
    }
    
    func setImage(id: UUID, image: UIImage?) throws {
        let fileName = "\(id.uuidString)-image.jpg"
        let destinationURL = self.documentFolder.appendingPathComponent(fileName)
        
        if let image = image {
            guard let data = image.jpegData(compressionQuality: 0.9) else {
                throw SelfieStoreError.cannotSaveImage(image)
            }
            try data.write(to: destinationURL)
        } else {
            try FileManager.default.removeItem(at: destinationURL)
        }
        
        imageCache[id] = image
    }
    
    func listSelfies() throws -> [Selfie] {
        let contents = try FileManager.default.contentsOfDirectory(at: self.documentFolder, includingPropertiesForKeys: nil)
        
        return try contents.filter { $0.pathExtension == "json" }
            .map { try Data(contentsOf: $0) }
            .map { try JSONDecoder().decode(Selfie.self, from: $0) }
    }
    
    func delete(selfie: Selfie) throws {
        
        try delete(id: selfie.id)
//        throw SelfieStoreError.cannotSaveImage(nil)
    }
    
    func delete(id: UUID) throws {
        let selfieDataFileName = "\(id.uuidString).json"
        let imageFileName = "\(id.uuidString)-image.jpg"

        let selfieDataURL = self.documentFolder.appendingPathComponent(selfieDataFileName)
        let imageURL = self.documentFolder.appendingPathComponent(imageFileName)
        
        if FileManager.default.fileExists(atPath: selfieDataURL.path) {
            try FileManager.default.removeItem(at: selfieDataURL)
        }
        
        if FileManager.default.fileExists(atPath: imageURL.path) {
            try FileManager.default.removeItem(at: imageURL)
        }
        
        imageCache[id] = nil
//        throw SelfieStoreError.cannotSaveImage(nil)
    }
    
    func load(id: UUID) -> Selfie? {
        let dataFileName = "\(id.uuidString).json"
        
        let dataURL = self.documentFolder.appendingPathComponent(dataFileName)
        
        if let data = try? Data(contentsOf: dataURL),
            let selfie = try? JSONDecoder().decode(Selfie.self, from: data) {
            return selfie
        } else {
            return nil
        }
    }
    
    func save(selfie: Selfie) throws {
        let selfieData = try JSONEncoder().encode(selfie)
        
        let fileName = "\(selfie.id.uuidString).json"
        let destinationURL = self.documentFolder.appendingPathComponent(fileName)
        
        try selfieData.write(to: destinationURL)
//        throw SelfieStoreError.cannotSaveImage(nil)
    }
}

// implement the Error protocol
enum SelfieStoreError: Error {
    case cannotSaveImage(UIImage?)
}
