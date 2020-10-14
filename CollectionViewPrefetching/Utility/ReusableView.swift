
import UIKit

public typealias ReusableNibView = ReusableView & NibLoadable

// MARK: - ReusableView
public protocol ReusableView {
    static var reuseIdentifier: String { get }
}

extension ReusableView {
    public static var reuseIdentifier: String {
        return String(describing: self)
    }
}

// MARK: - NibLoadable
public protocol NibLoadable {
    static var nibName: String { get }
    static var bundle: Bundle { get }
}

public extension NibLoadable where Self: UIView {
    static var nibName: String {
        return String(describing: self)
    }
    
    static var bundle: Bundle {
        return Bundle(for: Self.self)
    }
    
    static var nib: UINib {
        return UINib(nibName: nibName, bundle: bundle)
    }
    
    static func loadFromNib(owner: Any? = nil, options: [UINib.OptionsKey: Any]? = nil) -> Self? {
        return bundle.loadNibNamed(Self.nibName, owner: owner, options: options)?.first as? Self
    }
    
    func viewFromNib(options: [UINib.OptionsKey: Any]? = nil) -> UIView? {
        return Self.bundle.loadNibNamed(Self.nibName, owner: self, options: options)?.first as? UIView
    }
}
