# Text & link editor
`UItextView` based text editor mimicking Apple's Notes app
* Tap on a link to open it in a browser
* Tap anywhere else to start editing

## Description
`UITextView` does not support tap to edit out of the box. To solve that we do the following
* Recognize tap gesture on `UITextView`
* Calculate the nearest cursor position
* Use `NSLayoutManager` and `NSTextStorage` api to detect whether tap location contains a link

## Preview
![editor](https://github.com/moubarak/text-editor/assets/885084/1873dd11-8c5b-489a-9a5e-fa31743faf91)
