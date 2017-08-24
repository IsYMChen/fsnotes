//
//  EditTextView.swift
//  FSNotes
//
//  Created by Oleksandr Glushchenko on 8/11/17.
//  Copyright © 2017 Oleksandr Glushchenko. All rights reserved.
//

import Cocoa

class EditTextView: NSTextView {
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    var currentNote = Note()
        
    func fill(note: Note) {
        self.currentNote = note
        
        self.isEditable = true
        self.isRichText = note.isRTF()

        let attrString = createAttributedString(note: note)
        self.textStorage?.setAttributedString(attrString)
        
        if (!currentNote.isRTF()) {
            self.textStorage?.font = UserDefaultsManagement.noteFont
        }
        
        let viewController = self.window?.contentViewController as! ViewController
        viewController.emptyEditAreaImage.isHidden = true
    }
    
    func save(note: Note) -> Bool {
        let fileUrl = note.url
        let fileExtension = fileUrl?.pathExtension
        
        do {
            let range = NSRange(location:0, length: (textStorage?.string.characters.count)!)
            let documentAttributes = DocumentAttributes.getDocumentAttributes(fileExtension: fileExtension!)
            
            if (fileExtension == "rtf") {
                let text = try textStorage?.fileWrapper(from: range, documentAttributes: documentAttributes)
                
                try text?.write(to: fileUrl!, options: FileWrapper.WritingOptions.atomic, originalContentsURL: nil)
            } else {
                textStorage?.setAttributes(documentAttributes, range: range)
                
                try textStorage?.string.write(to: fileUrl!, atomically: false, encoding: String.Encoding.utf8)
            }
            
            return true
        } catch let error {
            NSLog(error.localizedDescription)
        }
        
        return false
    }
    
    func clear() {
        textStorage?.mutableString.setString("")
        isEditable = false
        
        let viewController = self.window?.contentViewController as! ViewController
        viewController.emptyEditAreaImage.isHidden = false
    }
    
    func createAttributedString(note: Note) -> NSAttributedString {
        let url = note.url
        let fileExtension = url?.pathExtension
        let options = DocumentAttributes.getDocumentAttributes(fileExtension: fileExtension!)
        var attributedString = NSAttributedString()
        
        do {
            attributedString = try NSAttributedString(url: url!, options: options, documentAttributes: nil)
        } catch {
            NSLog("No text content found!")
        }
        
        return attributedString
    }
    
    override func mouseDown(with event: NSEvent) {
        let viewController = self.window?.contentViewController as! ViewController
        if (!viewController.emptyEditAreaImage.isHidden) {
            viewController.makeNote(NSTextField())
        }
        return super.mouseDown(with: event)
    }
    
    /*
    override func keyDown(with event: NSEvent) {
        
        if (event.keyCode == 36) {
            if (!currentNote.isRTF()) {
                let range = selectedRange()
                textStorage?.insert(NSAttributedString(string: "\n ###"), at: range.location)
                setSelectedRange(NSRange.init(location: range.location + 5, length: 0))
                Swift.print(range.location)
            }
        }
        
        super.keyDown(with: event)
    }
     */
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if (event.modifierFlags.contains(.command) && isEditable) {
            let range = selectedRange()
            let text = textStorage!.string as NSString
            let selectedText = text.substring(with: range) as NSString
            let attributedText = NSMutableAttributedString(string: selectedText as String)
            let options = DocumentAttributes.getDocumentAttributes(fileExtension: currentNote.url.pathExtension)
            
            attributedText.addAttributes(options, range: NSMakeRange(0, selectedText.length))
            
            switch event.keyCode {
            case 11: // cmd-b
                if (!currentNote.isRTF()) {
                    attributedText.mutableString.setString("**" + attributedText.string + "**")
                } else {
                    textStorage?.applyFontTraits(NSFontTraitMask(rawValue: NSFontTraitMask.RawValue(NSFontBoldTrait)), range: range)
                }
                break
            case 34: // cmd-i
                if (!currentNote.isRTF()) {
                    attributedText.mutableString.setString("_" + attributedText.string + "_")
                } else {
                    textStorage?.applyFontTraits(NSFontTraitMask(rawValue: NSFontTraitMask.RawValue(NSFontItalicTrait)), range: range)
                }
                break
            case 32: // cmd-u
                if (currentNote.isRTF()) {
                    attributedText.addAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyle.styleSingle.rawValue, range: NSMakeRange(0, selectedText.length))
                }
                break
            case 16: // cmd-y
                if (currentNote.isRTF()) {
                    attributedText.addAttribute(NSStrikethroughStyleAttributeName, value: 2, range: NSMakeRange(0, selectedText.length))
                } else {
                    attributedText.mutableString.setString("~~" + attributedText.string + "~~")
                }
            case (18...23): // cmd-1/6 (headers 1/6)
                if (!currentNote.isRTF()) {
                    var string = ""
                    var offset = 2
    
                    for index in [18,19,20,21,23,22] {
                        string = string + "#"
                        offset = offset + 1
                        if event.keyCode == index {
                            break
                        }
                    }
                    
                    let range = selectedRange()
                    textStorage?.insert(NSAttributedString(string: string + " "), at: range.location)
                    setSelectedRange(NSRange.init(location: range.location + offset, length: 0))
                }
                break
            default:
                return super.performKeyEquivalent(with: event)
            }
            
            if (![11, 34].contains(event.keyCode) || !currentNote.isRTF()) {
                textStorage!.replaceCharacters(in: range, with: attributedText)
            }
            
            return save(note: currentNote)
        }
        
        if (event.keyCode == 36) {
            return false
        }
        
        return super.performKeyEquivalent(with: event)
    }
}
