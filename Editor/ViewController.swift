//
//  ViewController.swift
//  Editor
//
//  Created by Mohamed on 6/6/24.
//

import UIKit

class ViewController: UIViewController {
    
    // View
    let editorView = UITextView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        setupEditorView()
        self.view.addSubview(editorView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Autolayout
        editorView.translatesAutoresizingMaskIntoConstraints = false
        let safeViewMargins = self.view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            editorView.leadingAnchor.constraint(equalTo: safeViewMargins.leadingAnchor),
            editorView.trailingAnchor.constraint(equalTo: safeViewMargins.trailingAnchor),
            editorView.topAnchor.constraint(equalTo: safeViewMargins.topAnchor),
            editorView.bottomAnchor.constraint(equalTo: safeViewMargins.bottomAnchor),
        ])
    }
    
    private func setupEditorView() {
        
        editorView.isSelectable = true
        editorView.isUserInteractionEnabled = true
        editorView.font = .systemFont(ofSize: 21)
        editorView.text = "Edit Me!\n\nHello World\nwww.google.com"
        editorView.dataDetectorTypes = .link
        editorView.becomeFirstResponder()
        
        // Initial state
        switchToEditingState()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        editorView.addGestureRecognizer(tap)
    }
    
    @objc private func handleTap(_ tap: UITapGestureRecognizer) {
        guard let textVIew = tap.view as? UITextView else {
            return
        }
        
        var tapLocation = tap.location(in: textVIew)
        // Convert view coordinates to text container coordinates
        tapLocation.x -= textVIew.textContainerInset.left
        tapLocation.y -= textVIew.textContainerInset.top
        
        // Update the cursor position
        updateCursor(textVIew, tapLocation)
        
        // Determine whether user tapped on a link or not
        openLinkOrEditText(textVIew, tapLocation)
    }
    
    private func updateCursor(_ textView: UITextView, 
                              _ location: CGPoint) {
        // Position the cursor at the nearest location
        if let textPosition = textView.closestPosition(to: location) {
            // Find offset from beggining of document
            let offset = textView.offset(from: textView.beginningOfDocument, to: textPosition)
            // Position the cursor
            textView.selectedRange = NSMakeRange(offset, 0)
        }
    }
    
    private func openLinkOrEditText(_ textVIew: UITextView,
                                    _ location: CGPoint) {
        
        let layoutManager = textVIew.layoutManager
        // Convert tap coordinates to the nearest glyph index
        let glyphIndex: Int = layoutManager.glyphIndex(for: location, in: textVIew.textContainer, fractionOfDistanceThroughGlyph: nil)
        // Check to see whether the mouse actually lies over the glyph it is nearest to
        let glyphRect = layoutManager.boundingRect(forGlyphRange: NSRange(location: glyphIndex, length: 1), in: textVIew.textContainer)
        
        if glyphRect.contains(location) {
            // Convert the glyph index to a character index
            let characterIndex: Int = layoutManager.characterIndexForGlyph(at: glyphIndex)
            let attributeName = NSAttributedString.Key.link
            // Get the attribute at charater index
            let attributeValue = textVIew.textStorage.attribute(attributeName, at: characterIndex, effectiveRange: nil)
            // Check if the attrivute is a link
            if let url = attributeValue as? URL {
                // Open the link in a browser
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            } else {
                switchToEditingState()
            }
        } else {
            switchToEditingState()
        }
    }
    
    // State
    private func switchToEditingState() {
        if isEditing { return }
        isEditing = true
    }
    
    // Handle state changes
    override func setEditing(_ editing: Bool, 
                             animated: Bool) {
        super.setEditing(editing, animated: animated)
        if !editing {
            editorView.isEditable = false
            navigationItem.rightBarButtonItem = nil
            editorView.resignFirstResponder()
            editorView.dataDetectorTypes = .link
        } else {
            editButtonItem.tintColor = UIColor.white
            navigationItem.rightBarButtonItem = editButtonItem
            editorView.isEditable = true
            editorView.becomeFirstResponder()
        }
    }
}

extension UIColor {
    public class var appleNotes: UIColor {
        return UIColor(red: 255/255, green: 187/255, blue: 28/255, alpha: 1)
    }
}
