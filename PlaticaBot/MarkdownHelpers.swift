//
//  MarkdownHelpers.swift
//  platicador
//
//  Created by Miguel de Icaza on 3/12/23.
//

import Foundation
import Markdownosaur
import Markdown

public func markdownToAttributedString (document: Document) -> AttributedString {
    var markdownosaur = Markdownosaur()
    let attributedString = markdownosaur.attributedString(from: document)
    return AttributedString (attributedString)
}

public func markdownToAttributedString (text: String) -> AttributedString {
    let document = Document(parsing: text)
    return markdownToAttributedString(document: document)
}
