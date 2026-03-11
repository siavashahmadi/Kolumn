import SwiftUI
import AppKit

struct ToolbarTextField: NSViewRepresentable {
    var placeholder: String
    @Binding var text: String
    @Binding var isFocused: Bool
    var onSubmit: () -> Void

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.focusRingType = .none
        textField.placeholderString = placeholder
        textField.bezelStyle = .roundedBezel
        textField.delegate = context.coordinator
        textField.stringValue = text
        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
        if isFocused {
            DispatchQueue.main.async {
                nsView.window?.makeFirstResponder(nsView)
                self.isFocused = false
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: ToolbarTextField

        init(_ parent: ToolbarTextField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            parent.text = textField.stringValue
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                parent.onSubmit()
                return true
            }
            return false
        }
    }
}
