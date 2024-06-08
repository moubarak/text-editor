# Text & link editor
`UItextView` based text editor mimicking Apple's Notes with an additional feature to open links in edit mode
* Tap on a link to open it
* Tap anywhere else to edit text

## Details
`UITextView` does not support tap to edit. Moreover it doesn't open links while editing. To fix this we do the following
* Recognize tap gesture on `UITextView`
* Calculate the nearest cursor position
* Use `NSLayoutManager` and `NSTextStorage` apis to detect whether the tap location contains a link and open it

## Preview

![editor](https://github.com/moubarak/text-editor/assets/885084/5f86f355-5177-4d86-a394-b956d6fca091)

## Note
This code is based on the MVC architecture and UIKit. It is missing some basic features like scrolling, persistance, etc.
