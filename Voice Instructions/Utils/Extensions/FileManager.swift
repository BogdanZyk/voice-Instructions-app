//
//  FileManager.swift
//  Voice Instructions
//
//

import Foundation


extension FileManager{
    
    
    func createVideoPath(with name: String) -> URL?{
        guard let url = self.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(name) else { return nil}
        return url
    }
        
    func removeFileIfExists(for url: URL){
        if fileExists(atPath: url.path){
            do{
                try removeItem(at: url)
            }catch{
                print("Error to remove item", error.localizedDescription)
            }
        }
    }
}
