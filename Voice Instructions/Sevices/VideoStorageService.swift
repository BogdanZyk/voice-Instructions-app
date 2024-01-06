//
//  VideoStorageService.swift
//  Voice Instructions
//
//

import Foundation


class VideoStorageService {

    static let shared = VideoStorageService()
    private let userDefault = UserDefaults.standard
    private let userDataKey = "videoStorageService"
    private init(){}


    func save(_ model: Video){
        userDefault.saveObject(model, key: userDataKey)
    }


    func load() -> Video?{
        userDefault.loadObject(key: userDataKey)
    }

    func remove(){
        userDefault.removeObject(forKey: userDataKey)
    }
}
