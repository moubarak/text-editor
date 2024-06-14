//
//  UITextView.swift
//  Editor
//
//  Created by Mohamed on 12-06-2024.
//

import UIKit

let customLinkTag = "customLink"

extension UITextView: UITextViewInteractor {
    func text(in range: NSRange) -> String {
        return textStorage.attributedSubstring(from: range).string
    }
    
    func link(in selectedRange: NSRange) -> (URL?, NSRange?) {
        let textRange = NSMakeRange(0, textStorage.length)
        var url: URL?
        var urlRange: NSRange?
        var count = 0
        textStorage.enumerateAttribute(.link, in: textRange) { value, attributedRange, shouldStop in
            if let link = value,
               let foundURL = URL(string: String(describing: link)) ?? value as? URL,
               let _ = selectedRange.intersection(attributedRange) {
                url = foundURL
                urlRange = attributedRange
                count += 1
            }
        }
        if let url = url,
           count == 1 {
            return (url, urlRange)
        }
        return (nil, nil)
    }
    
    internal func refreshLinks() {
        let textRange = NSMakeRange(0, textStorage.length)
        textStorage.enumerateAttribute(.link, in: textRange) { value, attributeRange, _ in
            if let _ = value as? URL,
               !textStorage.attributes(at: attributeRange.location, longestEffectiveRange: nil, in: attributeRange).contains(where: { (key: NSAttributedString.Key, value: Any) in
                   key == .textItemTag && (value as? String == customLinkTag)
               }) {
                textStorage.removeAttribute(.link, range: attributeRange)
            }
        }
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        detector.enumerateMatches(in: text,
                                  range: textRange)
        { (result, _, _) in
            if let url = result?.url,
               let range = result?.range,
               !textStorage.attributes(at: range.location, longestEffectiveRange: nil, in: range).contains(where: { (key: NSAttributedString.Key, value: Any) in
                   key == .textItemTag && (value as? String == customLinkTag)
               }) {
                textStorage.addAttribute(.link, value: url, range: range)
            }
        }
    }
    
    internal func handleKeyboardChanges() {
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.addObserver(self,
                                       selector: #selector(adjustForKeyboard),
                                       name: UIResponder.keyboardWillHideNotification,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(adjustForKeyboard),
                                       name: UIResponder.keyboardWillChangeFrameNotification,
                                       object: nil)
    }
    
    @objc internal func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = convert(keyboardScreenEndFrame, from: window)
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            contentInset = .zero
        } else {
            contentInset = UIEdgeInsets(top: 0,
                                        left: 0,
                                        bottom: keyboardViewEndFrame.height - safeAreaInsets.bottom,
                                        right: 0)
        }

        scrollIndicatorInsets = contentInset
        scrollRangeToVisible(selectedRange)
    }
    
    internal func updateCursor(_ location: CGPoint) {
        // Position the cursor at the nearest location
        if let textPosition = closestPosition(to: location) {
            // Find offset from beggining of document
            let offset = offset(from: beginningOfDocument, to: textPosition)
            // Position the cursor
            selectedRange = NSMakeRange(offset, 0)
        }
    }
    
    internal func handleTap(_ location: CGPoint,
                            _ completion: ((URL?, NSRange?) -> Void)) {
        // Convert tap coordinates to the nearest glyph index
        let glyphIndex: Int = layoutManager.glyphIndex(for: location, in: textContainer)
        let glyphRect = layoutManager.boundingRect(forGlyphRange: NSRange(location: glyphIndex, length: 1), in: textContainer)
        // Check whether the tap actually lies over the glyph it is nearest to
        if glyphRect.contains(location) {
            // Convert the glyph index to a character index
            let characterIndex: Int = layoutManager.characterIndexForGlyph(at: glyphIndex)
            if text(in: NSRange(location: characterIndex, length: 1)) == "\n" {
                completion(nil, nil)
            }
            else {
                // Find link attributed to this character and open it
                self.findLinkAtIndex(characterIndex) { foundURL, inRange in
                    completion(foundURL, inRange)
                }
            }
        } else {
            completion(nil, nil)
        }
    }
    
    internal func findLinkAtIndex(_ characterIndex: Int,
                                  _ completion: (URL?, NSRange?) -> (Void)) {
        var isLink = false
        let textLength = textStorage.length
        let textRange = NSRange(location: 0, length: textLength)
        textStorage.enumerateAttribute(.link, in: textRange)
        { value, range, stopEnumeration in
            if range.contains(characterIndex),
               let link = value,
               let url = URL(string: String(describing: link)) ?? value as? URL {
                completion(url, range)
                stopEnumeration.pointee = true
            }
            isLink = stopEnumeration.pointee.boolValue
        }
        if (!isLink) { completion(nil, nil) }
    }
}
