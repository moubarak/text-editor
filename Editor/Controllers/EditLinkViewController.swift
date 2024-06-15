//
//  EditLinkViewController.swift
//  Editor
//
//  Created by Mohamed on 13-06-2024.
//

import UIKit

class EditLinkViewController: UIViewController {
    internal var editorInteractor: EditorInteractor?
    private var _url: URL?
    var url: URL? {
        set {
            _url = newValue
        }
        get {
            return _url
        }
    }
    private var range: NSRange!
    private var name: String!
    private var urlTextView: UITextView!
    private var nameTextField: UITextField!
    private var linkToLabel: UILabel!
    private var nameLabel: UILabel!
    private var doneButton: UIBarButtonItem!
    private var removeLinkButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        configureUI()
    }
    
    private func configureUI() {
        title = "Edit Link"
        view.backgroundColor = .systemGroupedBackground
        
        doneButton = UIBarButtonItem(title: "Done",
                                     style: .done,
                                     target: self,
                                     action: #selector(doneTapped))
        doneButton.setTitleTextAttributes([.foregroundColor : primaryColor], for: .normal)
        doneButton.setTitleTextAttributes([.foregroundColor : primaryColor], for: .selected)
        navigationItem.rightBarButtonItem = doneButton
        
        let cancelButton = UIBarButtonItem(title: "Cancel",
                                     style: .plain,
                                     target: self,
                                     action: #selector(cancelTapped))
        cancelButton.setTitleTextAttributes([.foregroundColor : primaryColor], for: .normal)
        cancelButton.setTitleTextAttributes([.foregroundColor : primaryColor], for: .selected)
        navigationItem.leftBarButtonItem = cancelButton
        
        let defaultFont: UIFont = .systemFont(ofSize: 21)
        let labelFont: UIFont = .systemFont(ofSize: 15)
        
        linkToLabel = UILabel()
        linkToLabel.text = "LINK TO"
        linkToLabel.font = labelFont
        linkToLabel.textColor = .darkGray
        view.addSubview(linkToLabel)
        
        urlTextView = UITextView()
        urlTextView.isEditable = true
        urlTextView.clipsToBounds = true
        urlTextView.layer.cornerRadius = 5.0
        urlTextView.autocorrectionType = .no
        urlTextView.text = url?.absoluteString ?? ""
        urlTextView.font = defaultFont
        urlTextView.delegate = self
        urlTextView.tintColor = .black
        urlTextView.dataDetectorTypes = []
        urlTextView.autocorrectionType = .no
        urlTextView.autocapitalizationType = .none
        urlTextView.isSelectable = false
        urlTextView.isEditable = true
        view.addSubview(urlTextView)
        view.bringSubviewToFront(urlTextView)
        
        nameLabel = UILabel()
        nameLabel.text = "NAME"
        nameLabel.font = labelFont
        nameLabel.textColor = .darkGray
        view.addSubview(nameLabel)
        
        nameTextField = UITextField()
        nameTextField.borderStyle = .roundedRect
        nameTextField.text = name
        nameTextField.clearButtonMode = .unlessEditing
        nameTextField.font = defaultFont
        nameTextField.autocorrectionType = .no
        view.addSubview(nameTextField)
        
        removeLinkButton = UIButton(type: .custom)
        removeLinkButton.setTitle("Remove Link", for: .normal)
        removeLinkButton.setTitleColor(.red, for: .normal)
        removeLinkButton.addTarget(self, action: #selector(removeLink), for: .touchUpInside)
        view.addSubview(removeLinkButton)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Autolayout
        urlTextView.translatesAutoresizingMaskIntoConstraints = false
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        linkToLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        removeLinkButton.translatesAutoresizingMaskIntoConstraints = false
        let safeViewMargins = self.view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            linkToLabel.leadingAnchor.constraint(equalTo: urlTextView.leadingAnchor),
            linkToLabel.topAnchor.constraint(equalTo: safeViewMargins.topAnchor, constant: 15),
            
            urlTextView.leadingAnchor.constraint(equalTo: safeViewMargins.leadingAnchor, constant: 20),
            urlTextView.trailingAnchor.constraint(equalTo: safeViewMargins.trailingAnchor, constant: -20),
            urlTextView.topAnchor.constraint(equalTo: linkToLabel.bottomAnchor, constant: 5),
            urlTextView.heightAnchor.constraint(equalToConstant: 90),
            
            nameLabel.leadingAnchor.constraint(equalTo: urlTextView.leadingAnchor),
            nameLabel.topAnchor.constraint(equalTo: urlTextView.bottomAnchor, constant: 30),
            
            nameTextField.leadingAnchor.constraint(equalTo: safeViewMargins.leadingAnchor, constant: 20),
            nameTextField.trailingAnchor.constraint(equalTo: urlTextView.trailingAnchor),
            nameTextField.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 5),
            nameTextField.heightAnchor.constraint(equalToConstant: 45),
            
            removeLinkButton.leadingAnchor.constraint(equalTo: urlTextView.leadingAnchor),
            removeLinkButton.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 30),
        ])
    }
    
    func setRange(range: NSRange) {
        self.range = range
    }
    
    func setName(name: String) {
        self.name = name
    }
    
    @objc func removeLink() {
        editorInteractor?.removeURL(in: range)
        dismiss(animated: true)
    }
    
    @objc func doneTapped() {
        
        var name: String?
        if let newName = nameTextField.text,
           !newName.isEmpty {
            name = newName
        }
        
        var url: URL?
        if let urlString = urlTextView.text,
           !urlString.isEmpty {
            if urlString.hasPrefix("https://") || urlString.hasPrefix("http://") {
                url = URL(string: urlString)
            } else {
                let correctedURL = "https://\(urlString)"
                url = URL(string: correctedURL)
            }
            
            if let url = url {
                editorInteractor?.replaceURL(in: range, with: url, title: name)
            }
        }
        dismiss(animated: true)
    }
    
    @objc func cancelTapped() {
        dismiss(animated: true)
    }
}

extension EditLinkViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        doneButton.isEnabled = islink(in: textView.text)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return text != "\n"
    }
    
    func islink(in text: String) -> Bool {
        var isLink = false
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        detector.enumerateMatches(in: text,
                                  range: NSMakeRange(0, text.count))
        { (result, _, shouldStop) in
            if let _ = result?.url {
                isLink = true
                shouldStop.pointee = true
            }
        }
        
        return isLink
    }
}
