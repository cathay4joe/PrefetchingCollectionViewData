import UIKit

public struct DequeueConfig<Item, Cell> where Cell: UIView {
    
    public enum Kind {
        case `default`
        case nib(() -> UINib)
        case storyboard
    }
    
    // MARK: - Property
    public let kind: Kind
    public let identifier: String
    public let configure: (Item, Cell) -> Void
    
    // MARK: - Initializer
    public init(kind: Kind = .default,
                identifier: String = String(describing: Cell.self),
                configure: @escaping (Item, Cell) -> Void)
    {
        self.kind = kind
        self.identifier = identifier
        self.configure = configure
    }
    
    public static func nib(
        _ nib: @autoclosure @escaping () -> UINib,
        identifier: String = String(describing: Cell.self),
        configure: @escaping (Item, Cell) -> Void) -> DequeueConfig
    {
        return .init(kind: .nib(nib), identifier: identifier, configure: configure)
    }
}

extension DequeueConfig.Kind {
    fileprivate func transform<Root>() -> DequeueConfig<Root, Cell>.Kind {
        switch self {
        case .default: return .default
        case .nib(let nib): return .nib(nib)
        case .storyboard: return .storyboard
        }
    }
}

extension DequeueConfig {
    public func pullback<Root>(_ f: @escaping (Root) -> Item) -> DequeueConfig<Root, Cell> {
        return DequeueConfig<Root, Cell>(
            kind: kind.transform(),
            identifier: identifier,
            configure: { root, cell in self.configure(f(root), cell) }
        )
    }
}

extension DequeueConfig where Cell: Configurable , Cell.Item == Item {
    
    public static var `default`: DequeueConfig {
        return .init(
            configure: { item, cell in cell.configure(with: item) }
        )
    }
}

extension DequeueConfig where Cell: NibLoadable {
    
    public static func nib(
        identifier: String = String(describing: Cell.self),
        configure: @escaping (Item, Cell) -> Void) -> DequeueConfig
    {
        return .nib(Cell.nib, configure: configure)
    }
}


extension DequeueConfig where Cell: NibLoadable & Configurable, Cell.Item == Item {
    
    public static var nib: DequeueConfig {
        return .nib(Cell.nib, configure: { item, cell in cell.configure(with: item) } )
    }
}




