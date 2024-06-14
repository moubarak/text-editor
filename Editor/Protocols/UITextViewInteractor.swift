//
//  UITextViewDelegate.swift
//  Editor
//
//  Created by Mohamed on 12-06-2024.
//

import Foundation

protocol UITextViewInteractor {
    func refreshLinks()
    
    func handleKeyboardChanges()
    
    func adjustForKeyboard(notification: Notification)
    
    func updateCursor(_ location: CGPoint)
    
    func handleTap(_ location: CGPoint,
                   _ completion: ((URL?, NSRange?) -> Void))
    
    func findLinkAtIndex(_ characterIndex: Int,
                         _ completion: (URL?, NSRange?) -> (Void))
}
