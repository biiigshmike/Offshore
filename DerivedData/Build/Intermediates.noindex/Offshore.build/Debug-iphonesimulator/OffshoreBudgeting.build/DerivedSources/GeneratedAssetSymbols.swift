import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 11.0, macOS 10.13, tvOS 11.0, *)
extension ColorResource {

}

// MARK: - Image Symbols -

@available(iOS 11.0, macOS 10.7, tvOS 11.0, *)
extension ImageResource {

    /// The "Help-Budgets-1" asset catalog image resource.
    static let helpBudgets1 = ImageResource(name: "Help-Budgets-1", bundle: resourceBundle)

    /// The "Help-Budgets-2" asset catalog image resource.
    static let helpBudgets2 = ImageResource(name: "Help-Budgets-2", bundle: resourceBundle)

    /// The "Help-Budgets-3" asset catalog image resource.
    static let helpBudgets3 = ImageResource(name: "Help-Budgets-3", bundle: resourceBundle)

    /// The "Help-Cards-1" asset catalog image resource.
    static let helpCards1 = ImageResource(name: "Help-Cards-1", bundle: resourceBundle)

    /// The "Help-Cards-2" asset catalog image resource.
    static let helpCards2 = ImageResource(name: "Help-Cards-2", bundle: resourceBundle)

    /// The "Help-Cards-3" asset catalog image resource.
    static let helpCards3 = ImageResource(name: "Help-Cards-3", bundle: resourceBundle)

    /// The "Help-Home-1" asset catalog image resource.
    static let helpHome1 = ImageResource(name: "Help-Home-1", bundle: resourceBundle)

    /// The "Help-Home-2" asset catalog image resource.
    static let helpHome2 = ImageResource(name: "Help-Home-2", bundle: resourceBundle)

    /// The "Help-Home-3" asset catalog image resource.
    static let helpHome3 = ImageResource(name: "Help-Home-3", bundle: resourceBundle)

    /// The "Help-Income-1" asset catalog image resource.
    static let helpIncome1 = ImageResource(name: "Help-Income-1", bundle: resourceBundle)

    /// The "Help-Income-2" asset catalog image resource.
    static let helpIncome2 = ImageResource(name: "Help-Income-2", bundle: resourceBundle)

    /// The "Help-Income-3" asset catalog image resource.
    static let helpIncome3 = ImageResource(name: "Help-Income-3", bundle: resourceBundle)

    /// The "Help-Presets-1" asset catalog image resource.
    static let helpPresets1 = ImageResource(name: "Help-Presets-1", bundle: resourceBundle)

    /// The "Help-Presets-2" asset catalog image resource.
    static let helpPresets2 = ImageResource(name: "Help-Presets-2", bundle: resourceBundle)

    /// The "Help-Presets-3" asset catalog image resource.
    static let helpPresets3 = ImageResource(name: "Help-Presets-3", bundle: resourceBundle)

    /// The "Help-Settings-1" asset catalog image resource.
    static let helpSettings1 = ImageResource(name: "Help-Settings-1", bundle: resourceBundle)

    /// The "Help-Settings-2" asset catalog image resource.
    static let helpSettings2 = ImageResource(name: "Help-Settings-2", bundle: resourceBundle)

    /// The "Help-Settings-3" asset catalog image resource.
    static let helpSettings3 = ImageResource(name: "Help-Settings-3", bundle: resourceBundle)

    /// The "SettingsAppIcon" asset catalog image resource.
    static let settingsAppIcon = ImageResource(name: "SettingsAppIcon", bundle: resourceBundle)

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 10.13, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

}
#endif

#if canImport(UIKit)
@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

}
#endif

#if canImport(SwiftUI)
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.Color {

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 10.7, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    /// The "Help-Budgets-1" asset catalog image.
    static var helpBudgets1: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .helpBudgets1)
#else
        .init()
#endif
    }

    /// The "Help-Budgets-2" asset catalog image.
    static var helpBudgets2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .helpBudgets2)
#else
        .init()
#endif
    }

    /// The "Help-Budgets-3" asset catalog image.
    static var helpBudgets3: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .helpBudgets3)
#else
        .init()
#endif
    }

    /// The "Help-Cards-1" asset catalog image.
    static var helpCards1: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .helpCards1)
#else
        .init()
#endif
    }

    /// The "Help-Cards-2" asset catalog image.
    static var helpCards2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .helpCards2)
#else
        .init()
#endif
    }

    /// The "Help-Cards-3" asset catalog image.
    static var helpCards3: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .helpCards3)
#else
        .init()
#endif
    }

    /// The "Help-Home-1" asset catalog image.
    static var helpHome1: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .helpHome1)
#else
        .init()
#endif
    }

    /// The "Help-Home-2" asset catalog image.
    static var helpHome2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .helpHome2)
#else
        .init()
#endif
    }

    /// The "Help-Home-3" asset catalog image.
    static var helpHome3: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .helpHome3)
#else
        .init()
#endif
    }

    /// The "Help-Income-1" asset catalog image.
    static var helpIncome1: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .helpIncome1)
#else
        .init()
#endif
    }

    /// The "Help-Income-2" asset catalog image.
    static var helpIncome2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .helpIncome2)
#else
        .init()
#endif
    }

    /// The "Help-Income-3" asset catalog image.
    static var helpIncome3: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .helpIncome3)
#else
        .init()
#endif
    }

    /// The "Help-Presets-1" asset catalog image.
    static var helpPresets1: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .helpPresets1)
#else
        .init()
#endif
    }

    /// The "Help-Presets-2" asset catalog image.
    static var helpPresets2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .helpPresets2)
#else
        .init()
#endif
    }

    /// The "Help-Presets-3" asset catalog image.
    static var helpPresets3: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .helpPresets3)
#else
        .init()
#endif
    }

    /// The "Help-Settings-1" asset catalog image.
    static var helpSettings1: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .helpSettings1)
#else
        .init()
#endif
    }

    /// The "Help-Settings-2" asset catalog image.
    static var helpSettings2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .helpSettings2)
#else
        .init()
#endif
    }

    /// The "Help-Settings-3" asset catalog image.
    static var helpSettings3: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .helpSettings3)
#else
        .init()
#endif
    }

    /// The "SettingsAppIcon" asset catalog image.
    static var settingsAppIcon: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .settingsAppIcon)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// The "Help-Budgets-1" asset catalog image.
    static var helpBudgets1: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .helpBudgets1)
#else
        .init()
#endif
    }

    /// The "Help-Budgets-2" asset catalog image.
    static var helpBudgets2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .helpBudgets2)
#else
        .init()
#endif
    }

    /// The "Help-Budgets-3" asset catalog image.
    static var helpBudgets3: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .helpBudgets3)
#else
        .init()
#endif
    }

    /// The "Help-Cards-1" asset catalog image.
    static var helpCards1: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .helpCards1)
#else
        .init()
#endif
    }

    /// The "Help-Cards-2" asset catalog image.
    static var helpCards2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .helpCards2)
#else
        .init()
#endif
    }

    /// The "Help-Cards-3" asset catalog image.
    static var helpCards3: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .helpCards3)
#else
        .init()
#endif
    }

    /// The "Help-Home-1" asset catalog image.
    static var helpHome1: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .helpHome1)
#else
        .init()
#endif
    }

    /// The "Help-Home-2" asset catalog image.
    static var helpHome2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .helpHome2)
#else
        .init()
#endif
    }

    /// The "Help-Home-3" asset catalog image.
    static var helpHome3: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .helpHome3)
#else
        .init()
#endif
    }

    /// The "Help-Income-1" asset catalog image.
    static var helpIncome1: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .helpIncome1)
#else
        .init()
#endif
    }

    /// The "Help-Income-2" asset catalog image.
    static var helpIncome2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .helpIncome2)
#else
        .init()
#endif
    }

    /// The "Help-Income-3" asset catalog image.
    static var helpIncome3: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .helpIncome3)
#else
        .init()
#endif
    }

    /// The "Help-Presets-1" asset catalog image.
    static var helpPresets1: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .helpPresets1)
#else
        .init()
#endif
    }

    /// The "Help-Presets-2" asset catalog image.
    static var helpPresets2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .helpPresets2)
#else
        .init()
#endif
    }

    /// The "Help-Presets-3" asset catalog image.
    static var helpPresets3: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .helpPresets3)
#else
        .init()
#endif
    }

    /// The "Help-Settings-1" asset catalog image.
    static var helpSettings1: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .helpSettings1)
#else
        .init()
#endif
    }

    /// The "Help-Settings-2" asset catalog image.
    static var helpSettings2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .helpSettings2)
#else
        .init()
#endif
    }

    /// The "Help-Settings-3" asset catalog image.
    static var helpSettings3: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .helpSettings3)
#else
        .init()
#endif
    }

    /// The "SettingsAppIcon" asset catalog image.
    static var settingsAppIcon: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .settingsAppIcon)
#else
        .init()
#endif
    }

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 11.0, macOS 10.13, tvOS 11.0, *)
@available(watchOS, unavailable)
extension ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(UIKit)
@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 11.0, macOS 10.7, tvOS 11.0, *)
@available(watchOS, unavailable)
extension ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 10.7, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    private convenience init?(thinnableResource: ImageResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

// MARK: - Backwards Deployment Support -

/// A color resource.
struct ColorResource: Swift.Hashable, Swift.Sendable {

    /// An asset catalog color resource name.
    fileprivate let name: Swift.String

    /// An asset catalog color resource bundle.
    fileprivate let bundle: Foundation.Bundle

    /// Initialize a `ColorResource` with `name` and `bundle`.
    init(name: Swift.String, bundle: Foundation.Bundle) {
        self.name = name
        self.bundle = bundle
    }

}

/// An image resource.
struct ImageResource: Swift.Hashable, Swift.Sendable {

    /// An asset catalog image resource name.
    fileprivate let name: Swift.String

    /// An asset catalog image resource bundle.
    fileprivate let bundle: Foundation.Bundle

    /// Initialize an `ImageResource` with `name` and `bundle`.
    init(name: Swift.String, bundle: Foundation.Bundle) {
        self.name = name
        self.bundle = bundle
    }

}

#if canImport(AppKit)
@available(macOS 10.13, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// Initialize a `NSColor` with a color resource.
    convenience init(resource: ColorResource) {
        self.init(named: NSColor.Name(resource.name), bundle: resource.bundle)!
    }

}

protocol _ACResourceInitProtocol {}
extension AppKit.NSImage: _ACResourceInitProtocol {}

@available(macOS 10.7, *)
@available(macCatalyst, unavailable)
extension _ACResourceInitProtocol {

    /// Initialize a `NSImage` with an image resource.
    init(resource: ImageResource) {
        self = resource.bundle.image(forResource: NSImage.Name(resource.name))! as! Self
    }

}
#endif

#if canImport(UIKit)
@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// Initialize a `UIColor` with a color resource.
    convenience init(resource: ColorResource) {
#if !os(watchOS)
        self.init(named: resource.name, in: resource.bundle, compatibleWith: nil)!
#else
        self.init()
#endif
    }

}

@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// Initialize a `UIImage` with an image resource.
    convenience init(resource: ImageResource) {
#if !os(watchOS)
        self.init(named: resource.name, in: resource.bundle, compatibleWith: nil)!
#else
        self.init()
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.Color {

    /// Initialize a `Color` with a color resource.
    init(_ resource: ColorResource) {
        self.init(resource.name, bundle: resource.bundle)
    }

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.Image {

    /// Initialize an `Image` with an image resource.
    init(_ resource: ImageResource) {
        self.init(resource.name, bundle: resource.bundle)
    }

}
#endif