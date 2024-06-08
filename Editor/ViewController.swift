//
//  ViewController.swift
//  Editor
//
//  Created by Mohamed on 6/6/24.
//

import UIKit

class ViewController: UIViewController {
    
    // Views
    let editorView = UITextView()
    lazy var doneButton : UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .clear
        button.setTitle("Done", for: .normal)
        button.setTitle("Done", for: .selected)
        button.tintColor = UIColor.white
        button.addTarget(self, action: #selector(toggleState), for: .touchUpInside)
        return button
    }()
    
    // State
    var isTextEditing = false
    
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
        
        let attributedString = NSMutableAttributedString(string: "Some attributed text\ngoogle.com\nbing.com", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 21)])
        attributedString.addAttribute(.link, value: "https://www.google.com", range: NSRange(location: 21, length: 10))
        attributedString.addAttribute(.link, value: "https://www.bing.com", range: NSRange(location: 32, length: 8))
        
        editorView.isSelectable = true
        editorView.isUserInteractionEnabled = true
        editorView.attributedText = attributedString
        editorView.dataDetectorTypes = .link
        editorView.becomeFirstResponder()
        editorView.delegate = self
        
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
        
        openLinkOrEditText(tapLocation) {
            updateCursor(textVIew, tapLocation)
            switchToEditingState()
        }
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
    
    private func openLinkOrEditText(_ location: CGPoint,
                                    _ editText: (() -> Void)) {
        let layoutManager = editorView.layoutManager
        let textContainer = editorView.textContainer
        // Convert tap coordinates to the nearest glyph index
        let glyphIndex: Int = layoutManager.glyphIndex(for: location, in: textContainer, fractionOfDistanceThroughGlyph: nil)
        let glyphRect = layoutManager.boundingRect(forGlyphRange: NSRange(location: glyphIndex, length: 1), in: textContainer)
        // Check whether the tap actually lies over the glyph it is nearest to
        if glyphRect.contains(location) {
            // Convert the glyph index to a character index
            let characterIndex: Int = layoutManager.characterIndexForGlyph(at: glyphIndex)
            // Find link attributed to this character and open it
            findLinkAtIndex(characterIndex) { isFound in
                if !isFound {
                    editText()
                }
            }
        } else {
            editText()
        }
    }
    
    private func findLinkAtIndex(_ characterIndex: Int,
                                 _ completion: (Bool) -> (Void)) {
        var isLink = false
        let textLength = editorView.textStorage.length
        editorView.textStorage.enumerateAttribute(NSAttributedString.Key.link,
                                                in: NSMakeRange(0, textLength),
                                                options: [.longestEffectiveRangeNotRequired])
        { value, range, stopEnumeration in
            if range.contains(characterIndex),
               let link = value,
               let url = URL(string: String(describing: link)) {
                // Open the link in a browser
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
                isLink = true
                stopEnumeration.pointee = true
            }
        }
        // If not link found swotch to edit mode
        completion(isLink)
    }
    
    private func switchToEditingState() {
        if isTextEditing { return }
        toggleState()
    }
    
    // Change state
    @objc private func toggleState() {
        isTextEditing = !isTextEditing
        if !isTextEditing {
            editorView.isEditable = false
            navigationItem.setRightBarButton(nil, animated: true)
            editorView.resignFirstResponder()
        } else {
            navigationItem.setRightBarButton(doneButton.toBarButtonItem(), animated: true)
            editorView.isEditable = true
            editorView.becomeFirstResponder()
        }
    }
}

extension UIColor {
    class var appleNotes: UIColor {
        return UIColor(red: 255/255, green: 187/255, blue: 28/255, alpha: 1)
    }
}

extension ViewController: UITextViewDelegate {
    
    func textView(_ textView: UITextView, 
                  shouldChangeTextIn range: NSRange,
                  replacementText text: String) -> Bool {
        
        // Don't spill link attribute to newly typed text
        editorView.typingAttributes = [
            .font: UIFont.systemFont(ofSize: 21)
        ]

        return true
    }
}

extension UIButton {
    func toBarButtonItem() -> UIBarButtonItem? {
        return UIBarButtonItem(customView: self)
    }
}
