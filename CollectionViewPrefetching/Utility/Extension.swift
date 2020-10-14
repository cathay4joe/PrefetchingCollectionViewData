import Foundation
import CoreGraphics
import UIKit

extension NSString {
    public func sizeFit(bounds: CGSize, font: UIFont, style: NSParagraphStyle? = nil) -> CGSize {
        var attribute: [NSAttributedString.Key: Any] = [.font: font]
        if let style = style {
            attribute.merge([.paragraphStyle: style], uniquingKeysWith: { $1 })
        }
        return boundingRect(with: bounds, options: .usesLineFragmentOrigin, attributes: attribute, context: nil).size
    }
    
    public func sizeFitWidth(_ width: CGFloat, font: UIFont, style: NSParagraphStyle? = nil) -> CGSize {
        let bounds = CGSize(width: width, height: .greatestFiniteMagnitude)
        return sizeFit(bounds: bounds, font: font, style: style)
    }
    
    public func sizeFitHeight(_ height: CGFloat, font: UIFont, style: NSParagraphStyle? = nil) -> CGSize {
        let bounds = CGSize(width: .greatestFiniteMagnitude, height: height)
        return sizeFit(bounds: bounds, font: font, style: style)
    }
}
public extension CGSize {
    
    static func square(_ value: CGFloat) -> CGSize {
        return CGSize(width: value, height: value)
    }
    
    static let null = CGSize(width: -1, height: -1)
    
    func scaleAspectFit(bounds: CGSize) -> CGSize {
        let fitWidth = scaleWidth(to: bounds.width)
        return fitWidth.scaleHeight(to: min(fitWidth.height, bounds.height))
    }
    
    func scaleWidth(to width: CGFloat) -> CGSize {
        return CGSize(
            width: width,
            height: height * (width / self.width)
        )
    }
    
    func scaleHeight(to height: CGFloat) -> CGSize {
        return CGSize(
            width: width * (height / self.height),
            height: height
        )
    }
}
extension UIEdgeInsets {
    public static func all(_ value: CGFloat) -> UIEdgeInsets {
        return UIEdgeInsets(top: value, left: value, bottom: value, right: value)
    }
    
    public init(vertical: CGFloat, horizontal: CGFloat) {
        self.init(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
    }
    
    public init(_ keyPath: WritableKeyPath<UIEdgeInsets, CGFloat>, _ value: CGFloat) {
        var temp: UIEdgeInsets = .zero
        temp[keyPath: keyPath] = value
        self = temp
    }
    
    
    public var verticalSpacing: CGFloat {
        return top + bottom
    }
    
    public var horizontalSpacing: CGFloat {
        return left + right
    }
}
