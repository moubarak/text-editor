# Text & link editor
Text editor mimicking Apple's Notes with some additional features
* Tap to start editing
* Auto-detect links even while typing
* Open links in-app (local browser)
* Add/remove links from text

## Details
`UITextView` does not support tap to edit. Moreover it doesn't detect/open links while editing. To fix this we:
* Recognize tap gesture on `UITextView`
* Calculate the nearest cursor position
* Use `NSLayoutManager` and `NSTextStorage` apis to detect whether the tap location contains a link and open it
* Differentiate between auto-detected links and user created links using tags

## Preview

![Simulator Screen Recording - iPhone 15 - 2024-06-14 at 17 13 04](https://github.com/moubarak/text-editor/assets/885084/ef3c79b8-1626-43ba-9d21-aa9bf9bbd7f3)


## Note
This code is based on the MVC architecture and UIKit. It is missing some basic features like persistence, etc.
