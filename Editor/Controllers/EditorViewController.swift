//
//  ViewController.swift
//  Editor
//
//  Created by Mohamed on 6/6/24.
//

import UIKit
import WebKit

class EditorViewController: UIViewController {
    // Views
    let editorView = UITextView(usingTextLayoutManager: true)
    var doneButton: UIBarButtonItem!
    
    // Configs
    private let defaultAttributes = [
        NSAttributedString.Key.font: UIFont.systemFont(ofSize: 21)
    ]
    
    // State
    private var isTextEditing = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        configureUI()
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
            editorView.bottomAnchor.constraint(equalTo: safeViewMargins.bottomAnchor)
        ])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Initial state
        switchToEditingState()
    }
    
    private func configureUI() {
        editorView.isSelectable = false
        editorView.tintColor = primaryColor
        editorView.isUserInteractionEnabled = true
        editorView.typingAttributes = defaultAttributes
        editorView.dataDetectorTypes = []
        editorView.autocorrectionType = .no
        editorView.becomeFirstResponder()
        editorView.refreshLinks()
        editorView.interactions.removeAll(where: { $0 is UIDropInteraction
                                              || $0 is UIDragInteraction })
        editorView.delegate = self
        
        editorView.handleKeyboardChanges()
        
        // Navigation
        doneButton = UIBarButtonItem(title: "Done", 
                                     style: .done,
                                     target: self,
                                     action: #selector(toggleState))
        doneButton.setTitleTextAttributes([.foregroundColor : primaryColor], for: .normal)
        doneButton.setTitleTextAttributes([.foregroundColor : primaryColor], for: .selected)
        navigationItem.rightBarButtonItem = doneButton
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        editorView.addGestureRecognizer(tap)
        
        self.view.addSubview(editorView)
    }
    
    @objc private func handleTap(_ tap: UITapGestureRecognizer) {
        guard let textVIew = tap.view as? UITextView else {
            return
        }
        
        switch tap.state {
        case .began:
            break
        case .ended:
            var tapLocation = tap.location(in: textVIew)
            // Convert view coordinates to text container coordinates
            tapLocation.x -= textVIew.textContainerInset.left
            tapLocation.y -= textVIew.textContainerInset.top
            
            editorView.handleTap(tapLocation) { foundURL, inRange in
                if let url = foundURL,
                   let range = inRange {
                    openLocalBrowser(url: url, range: range)
                } else {
                    editorView.updateCursor(tapLocation)
                    switchToEditingState()
                }
            }
            break
        case .possible: break
        case .changed: break
        case .cancelled: break
        case .failed: break
        @unknown default: break
        }
    }
    
    @objc private func addLink() {
        openLocalBrowser(url: nil, range: editorView.selectedRange)
    }
    
    private func openLocalBrowser(url: URL?, range: NSRange) {
        let browserViewController = BrowserViewController()
        browserViewController.initialUrl = url
        browserViewController.range = range
        browserViewController.editorInteractor = self

        let browserNavigation = UINavigationController(rootViewController: browserViewController)
        browserNavigation.modalPresentationStyle = .popover
        self.navigationController?.present(browserNavigation, animated: true)
    }
    
    private func editLink(url: URL?, name: String, range: NSRange) {
        let editLinkViewController = EditLinkViewController()
        editLinkViewController.url = url
        editLinkViewController.setRange(range: range)
        editLinkViewController.setName(name: name)
        editLinkViewController.editorInteractor = self
        
        let editLinkNavigation = UINavigationController(rootViewController: editLinkViewController)
        editLinkNavigation.modalPresentationStyle = .popover
        self.navigationController?.present(editLinkNavigation, animated: true)
    }
    
    // Control state
    private func switchToEditingState() {
        editorView.becomeFirstResponder()
        if isTextEditing { return }
        toggleState()
    }
    
    @objc private func switchToReadingState() {
        editorView.resignFirstResponder()
        if self.isTextEditing { self.toggleState() }
    }
    
    // Handle state changes
    @objc private func toggleState() {
        isTextEditing = !isTextEditing
        if !isTextEditing {
            editorView.isEditable = false
            doneButton.isHidden = true
            editorView.resignFirstResponder()
        } else {
            doneButton.isHidden = false
            editorView.isEditable = true
            editorView.becomeFirstResponder()
        }
    }
}

extension EditorViewController: UITextViewDelegate, EditorInteractor, WKUIDelegate {
    func removeURL(in range: NSRange) {
        editorView.textStorage.removeAttribute(.link, range: range)
        editorView.textStorage.removeAttribute(.textItemTag, range: range)
    }
    
    func replaceURL(in range: NSRange, with url: URL, title: String?) {
        editorView.textStorage.replaceCharacters(in: range, with: title ?? url.absoluteString)
        let editedRange = NSMakeRange(range.location, (title ?? url.absoluteString).count)
        editorView.textStorage.addAttribute(.link, value: url, range: editedRange)
        editorView.textStorage.addAttribute(.textItemTag, value: customLinkTag, range: editedRange)
        
        if range.length > 0 {
            editorView.selectedRange = editedRange
        }
    }
    
    func textView(_ textView: UITextView,
                  shouldChangeTextIn range: NSRange,
                  replacementText text: String) -> Bool {
        
        editorView.typingAttributes = defaultAttributes
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        textView.refreshLinks()
    }
    
    func textView(_ textView: UITextView, 
                  primaryActionFor textItem: UITextItem,
                  defaultAction: UIAction) -> UIAction? {
        
        switch textItem.content {
        case .link(_):
            return .none
        case .textAttachment(_):
            return defaultAction
        case .tag(_):
            return defaultAction
        @unknown default:
            return .none
        }
    }
    
    func textView(_ textView: UITextView, 
                  editMenuForTextIn range: NSRange,
                  suggestedActions: [UIMenuElement]) -> UIMenu? {
        
        var actionTitle = "Add Link"
        let (url, _) = textView.link(in: range)
        if url != nil {
            actionTitle = "Edit Link"
        }
        if range.length > 0 {
            let addLinkAction = UIAction(title: actionTitle) { (action) in
                let (link, linkRange) = textView.link(in: range)
                self.editLink(url: link, name: textView.text(in: linkRange ?? range), range: linkRange ?? range)
            }
            
            var actions = suggestedActions
            actions.insert(addLinkAction, at: 0)
            return UIMenu(children: actions)
        }
        return UIMenu(children: suggestedActions)
    }
    
    func textView(_ textView: UITextView,
                  menuConfigurationFor textItem: UITextItem,
                  defaultMenu: UIMenu
    ) -> UITextItem.MenuConfiguration? {
        let name = textView.text(in: textItem.range)
        return switch textItem.content {
        case .link(let url):
            UITextItem.MenuConfiguration(
                preview: .default,
                menu: UIMenu(title: "",
                             image: nil,
                             identifier: nil,
                             options: UIMenu.Options.displayInline,
                             children: [UIAction(
                                title: "Edit Link",
                                image: UIImage(systemName: "pencil"),
                                identifier: nil,
                                discoverabilityTitle: nil,
                                state: .off) { _ in
                                    self.editLink(url: url, name: name, range: textItem.range)
            }]))
        default:
            UITextItem.MenuConfiguration(menu: defaultMenu)
        }
    }
}
