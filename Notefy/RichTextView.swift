import SwiftUI

enum RichTextAction {
    case bold
    case italic
    case strikethrough
    case bullet
    case quote
    case heading1
}

struct RichTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var action: RichTextAction?

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = true
        textView.isScrollEnabled = true
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 6, bottom: 8, right: 6)
        textView.delegate = context.coordinator
        textView.allowsEditingTextAttributes = false
        textView.tintColor = .label
        textView.keyboardDismissMode = .interactive
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }

        if let pending = action {
            context.coordinator.apply(action: pending, to: uiView)
            DispatchQueue.main.async {
                self.action = nil
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        @Binding var text: String

        private let bullet = "•"
        private let bulletWithSpace = "• "
        private let dash = "-"
        private let dashWithSpace = "- "
        private let newline = "\n"

        init(text: Binding<String>) {
            _text = text
        }

        func textViewDidChange(_ textView: UITextView) {
            text = textView.text
        }


        private func clampRange(_ range: NSRange, length: Int) -> NSRange {
            let loc = max(0, min(range.location, length))
            let len = max(0, min(range.length, length - loc))
            return NSRange(location: loc, length: len)
        }

        private func safeSubstring(_ s: NSString, range: NSRange) -> String {
            let r = clampRange(range, length: s.length)
            if r.length == 0 { return "" }
            return s.substring(with: r)
        }

        func apply(action: RichTextAction, to textView: UITextView) {
            let ns = (textView.text ?? "") as NSString
            let sel = textView.selectedRange
            let fullLen = ns.length
            let safeSel = clampRange(sel, length: fullLen)

            func selectionOrWord() -> NSRange {
                if safeSel.length > 0 { return safeSel }
                let delimiters = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
                var start = safeSel.location
                var end = safeSel.location

                while start > 0 {
                    let ch = ns.character(at: start - 1)
                    if let scalar = UnicodeScalar(ch), delimiters.contains(scalar) { break }
                    start -= 1
                }
                while end < fullLen {
                    let ch = ns.character(at: end)
                    if let scalar = UnicodeScalar(ch), delimiters.contains(scalar) { break }
                    end += 1
                }
                return NSRange(location: start, length: max(0, end - start))
            }

            func toggleInline(prefix: String, suffix: String) {
                var range = selectionOrWord()
                let selected = safeSubstring(ns, range: range) as NSString
                let beforeRange = NSRange(location: max(0, range.location - prefix.count), length: min(prefix.count, range.location))
                let afterRange = NSRange(location: min(fullLen, range.location + range.length), length: min(suffix.count, fullLen - (range.location + range.length)))

                let hasPrefix = safeSubstring(ns, range: beforeRange) == prefix
                let hasSuffix = safeSubstring(ns, range: afterRange) == suffix

                var newText = ns as String
                var newCursorLocation = range.location

                if hasPrefix && hasSuffix {
                    let nsNew = NSMutableString(string: newText)
                    nsNew.replaceCharacters(in: afterRange, with: "")
                    nsNew.replaceCharacters(in: beforeRange, with: "")
                    newText = nsNew as String
                    newCursorLocation = range.location - prefix.count
                } else {
                    let nsNew = NSMutableString(string: newText)
                    nsNew.insert(suffix, at: range.location + range.length)
                    nsNew.insert(prefix, at: range.location)
                    newText = nsNew as String
                    newCursorLocation = range.location + prefix.count
                }

                textView.text = newText
                text = newText
                textView.becomeFirstResponder()
                textView.selectedRange = NSRange(location: newCursorLocation, length: selected.length)
            }

            func toggleLinePrefix(_ marker: String) {
                let start = safeSel.location
                let end = safeSel.location + safeSel.length
                var cursor = start
                let mutable = NSMutableString(string: ns as String)

                var pos = start
                var delta = 0

                while pos <= end {
                    let lineRange = (mutable as NSString).lineRange(for: NSRange(location: pos, length: 0))
                    let line = (mutable as NSString).substring(with: lineRange)
                    let trimmed = line.trimmingCharacters(in: .newlines)

                    let hasMarker = trimmed.hasPrefix(marker)
                    let prefixLen = (line as NSString).range(of: trimmed).location

                    let markerRange = NSRange(location: lineRange.location + prefixLen, length: min(marker.count, max(0, lineRange.length - prefixLen)))
                    if hasMarker {
                        mutable.replaceCharacters(in: markerRange, with: "")
                        delta -= marker.count
                        if cursor >= markerRange.location { cursor = max(lineRange.location, cursor - marker.count) }
                    } else {
                        mutable.insert(marker, at: lineRange.location + prefixLen)
                        delta += marker.count
                        if cursor >= lineRange.location + prefixLen { cursor += marker.count }
                    }

                    pos = lineRange.location + lineRange.length + (hasMarker ? -marker.count : marker.count)
                }

                let newText = mutable as String
                textView.text = newText
                text = newText
                textView.becomeFirstResponder()
                textView.selectedRange = NSRange(location: cursor, length: safeSel.length + delta)
            }

            switch action {
            case .bold:
                toggleInline(prefix: "**", suffix: "**")
            case .italic:
                toggleInline(prefix: "_", suffix: "_")
            case .strikethrough:
                toggleInline(prefix: "~~", suffix: "~~")
            case .bullet:
                toggleLinePrefix("- ")
            case .quote:
                toggleLinePrefix("> ")
            case .heading1:
                toggleLinePrefix("# ")
            }
        }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText replacement: String) -> Bool {
            let nsText = (textView.text ?? "") as NSString
            let fullLen = nsText.length
            let safeRange = clampRange(range, length: fullLen)

            func apply(replacing r: NSRange, with str: String, cursor: Int) {
                let clampedR = clampRange(r, length: (textView.text as NSString?)?.length ?? 0)
                let newText = ((textView.text ?? "") as NSString).replacingCharacters(in: clampedR, with: str)
                textView.text = newText
                let newLen = (newText as NSString).length
                let newCursor = max(0, min(cursor, newLen))
                textView.selectedRange = NSRange(location: newCursor, length: 0)
                text = newText
            }

            let lineRange = nsText.lineRange(for: NSRange(location: safeRange.location, length: 0))
            let lineText = safeSubstring(nsText, range: lineRange)
            let lineTextNoNewline = lineText.trimmingCharacters(in: .newlines)

            let prefixLen = max(0, safeRange.location - lineRange.location)
            let prefixRange = NSRange(location: lineRange.location, length: prefixLen)
            let prefix = safeSubstring(nsText, range: prefixRange)

            if replacement == " " {
                if prefix == dash {
                    let replaceRange = NSRange(location: lineRange.location, length: prefixLen + 1)
                    let newCursor = lineRange.location + (bulletWithSpace as NSString).length
                    apply(replacing: replaceRange, with: bulletWithSpace, cursor: newCursor)
                    return false
                }
                if prefix == dashWithSpace {
                    let replaceRange = NSRange(location: lineRange.location, length: (dashWithSpace as NSString).length)
                    apply(replacing: replaceRange, with: bulletWithSpace, cursor: safeRange.location)
                    return false
                }
            }

            if replacement == newline {
                if lineTextNoNewline.hasPrefix(bulletWithSpace) || lineTextNoNewline == bullet {
                    let afterBullet = String(lineTextNoNewline.dropFirst((bulletWithSpace as NSString).length))
                    let isEmptyBulletLine = afterBullet.trimmingCharacters(in: .whitespaces).isEmpty

                    if isEmptyBulletLine {
                        let bulletPrefixRange = NSRange(location: lineRange.location, length: min((bulletWithSpace as NSString).length, lineRange.length))
                        let withoutBullet = nsText.replacingCharacters(in: bulletPrefixRange, with: "") as NSString
                        let adjustedCaret = max(0, safeRange.location - (bulletWithSpace as NSString).length)
                        let newText = withoutBullet.replacingCharacters(in: NSRange(location: adjustedCaret, length: 0), with: newline)
                        let cursor = adjustedCaret + 1
                        textView.text = newText
                        textView.selectedRange = NSRange(location: cursor, length: 0)
                        text = newText
                        return false
                    } else {
                        let insertion = newline + bulletWithSpace
                        let cursor = safeRange.location + (insertion as NSString).length
                        apply(replacing: safeRange, with: insertion, cursor: cursor)
                        return false
                    }
                }

                if lineTextNoNewline.hasPrefix(dashWithSpace) || prefix == dashWithSpace {
                    let convertRange = NSRange(location: lineRange.location, length: (dashWithSpace as NSString).length)
                    var interim = nsText.replacingCharacters(in: convertRange, with: bulletWithSpace) as NSString
                    let caretShift = (bulletWithSpace as NSString).length - (dashWithSpace as NSString).length
                    let adjustedCaret = safeRange.location + max(0, caretShift)
                    interim = interim.replacingCharacters(in: NSRange(location: adjustedCaret, length: 0), with: newline + bulletWithSpace) as NSString
                    let cursor = adjustedCaret + 1 + (bulletWithSpace as NSString).length
                    textView.text = interim as String
                    textView.selectedRange = NSRange(location: cursor, length: 0)
                    text = interim as String
                    return false
                }
            }

            if replacement.isEmpty && range.length == 1 {
                if lineTextNoNewline.hasPrefix(bulletWithSpace) {
                    let bulletStart = lineRange.location
                    let bulletEnd = bulletStart + (bulletWithSpace as NSString).length
                    if safeRange.location == bulletEnd {
                        let bulletPrefixRange = NSRange(location: bulletStart, length: (bulletWithSpace as NSString).length)
                        apply(replacing: bulletPrefixRange, with: "", cursor: bulletStart)
                        return false
                    }
                }
            }

            return true
        }
    }
}
