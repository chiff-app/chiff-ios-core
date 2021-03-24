//
//  Localizer.swift
//  chiff
//
//  Copyright: see LICENSE.md
//

#if canImport(UIKit)
import UIKit
#else
import Cocoa
#endif

protocol Localizable {
    var localized: String { get }
    #if canImport(UIKit)
    func attributedLocalized(color: UIColor) -> NSAttributedString
    #else
    func attributedLocalized(color: NSColor) -> NSAttributedString
    #endif
}

protocol XIBLocalizable {
    var localizationKey: String? { get set }
}

protocol LocalizerProtocol {
    func localize(string: String) -> String
    #if canImport(UIKit)
    func localize(string: String, accentColor: UIColor, font: UIFont?, attributes: [NSAttributedString.Key: Any]) -> NSMutableAttributedString
    #else
    func localize(string: String, accentColor: NSColor, font: NSFont?, attributes: [NSAttributedString.Key: Any]) -> NSMutableAttributedString
    #endif
}

public class Localizer: LocalizerProtocol {

    static var shared: LocalizerProtocol = Localizer()

    lazy var localizableDictionary: NSDictionary! = {
        #if !TARGET_INTERFACE_BUILDER
        let bundle = Bundle.main
        #else
        let bundle = Bundle(for: type(of: self))
        #endif
        if let path = bundle.path(forResource: "Localized", ofType: "plist") {
            return NSDictionary(contentsOfFile: path)
        }
        fatalError("Localizable file not found.")
    }()

    func localize(string: String) -> String {
        let localizableGroup = localizedGroup(string: string)

        // When the localizable is a Dictionary with at least a 'value' item
        guard let localizedString = localizableGroup["value"] as? String else {
            Logger.shared.error("Missing translation for: \(string)")
            return "(Translation missing)"
        }
        return localizedString
    }

    #if canImport(UIKit)
    func localize(string: String, accentColor: UIColor, font: UIFont?, attributes: [NSAttributedString.Key: Any]) -> NSMutableAttributedString {
        let localizableGroup = localizedGroup(string: string)

        // When the localizable is a Dictionary with at least a 'value' item
        guard let localizedString = localizableGroup["value"] as? String else {
            assertionFailure("Missing translation for: \(string)")
            return NSMutableAttributedString(string: "")
        }
        let attributedString = NSMutableAttributedString(string: localizedString, attributes: attributes)
        if let startString = localizableGroup["start"] as? String,
            let start = Int(startString) {
            var end: Int?
            if let endString = localizableGroup["end"] as? String {
                end = Int(endString)
            }
            var attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: accentColor]
            if let font = font {
                attributes[NSAttributedString.Key.font] = font as Any
            }
            attributedString.setAttributes(attributes, range: NSRange(start..<(end ?? localizedString.count)))
        }
        return attributedString
    }
    #else
    func localize(string: String, accentColor: NSColor, font: NSFont?, attributes: [NSAttributedString.Key: Any]) -> NSMutableAttributedString {
        let localizableGroup = localizedGroup(string: string)

        // When the localizable is a Dictionary with at least a 'value' item
        guard let localizedString = localizableGroup["value"] as? String else {
            assertionFailure("Missing translation for: \(string)")
            return NSMutableAttributedString(string: "")
        }
        let attributedString = NSMutableAttributedString(string: localizedString, attributes: attributes)
        if let startString = localizableGroup["start"] as? String,
            let start = Int(startString) {
            var end: Int?
            if let endString = localizableGroup["end"] as? String {
                end = Int(endString)
            }
            var attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: accentColor]
            if let font = font {
                attributes[NSAttributedString.Key.font] = font as Any
            }
            attributedString.setAttributes(attributes, range: NSRange(start..<(end ?? localizedString.count)))
        }
        return attributedString
    }
    #endif


    func localizedGroup(string: String) -> NSDictionary {
        var localizableGroup = localizableDictionary!
        let components = string.components(separatedBy: ".")

        for component in components {
            guard let localizedValue = localizableGroup[component] as? NSDictionary else {
                Logger.shared.error("Missing translation for: \(string)")
                return NSDictionary()
            }
            localizableGroup = localizedValue
        }

        return localizableGroup
    }

}

extension String {

    /// The localized string for this key. Should be in the format `"group.key"`.
    var localized: String {
        return Localizer.shared.localize(string: self)
    }

    /// The attributed string for this key, optionnaly overrding the font. The letters to color should be in the localization file.
    #if canImport(UIKit)
    func attributedLocalized(color: UIColor, font: UIFont?, attributes: [NSAttributedString.Key: Any]) -> NSMutableAttributedString {
        return Localizer.shared.localize(string: self, accentColor: color, font: font, attributes: attributes)
    }
    #else
    func attributedLocalized(color: NSColor, font: NSFont?, attributes: [NSAttributedString.Key: Any]) -> NSMutableAttributedString {
        return Localizer.shared.localize(string: self, accentColor: color, font: font, attributes: attributes)
    }
    #endif
}
