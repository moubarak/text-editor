//
//  EditorDelegate.swift
//  Editor
//
//  Created by Mohamed on 12-06-2024.
//

import Foundation

protocol EditorInteractor {
    func replaceURL(in range: NSRange, with url: URL, title: String?)
    
    func removeURL(in range: NSRange)
}
