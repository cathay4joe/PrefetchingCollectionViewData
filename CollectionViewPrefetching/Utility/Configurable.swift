
public protocol Configurable {
    associatedtype Item
    func configure(with item: Item)
}

extension Configurable {
    var configuring: Configuring<Self.Item, Self> {
        return Configuring { $1.configure(with: $0) }
    }
}

public struct Configuring<Setting, Item> {
    public let configure: (Setting, Item) -> Void
    public init(configure: @escaping (Setting, Item) -> Void) {
        self.configure = configure
    }
}

extension Configuring {
    public func pullback<RootSetting>(_ f: @escaping (RootSetting) -> Setting) -> Configuring<RootSetting, Item> {
        return Configuring<RootSetting, Item> { setting, item in
            self.configure(f(setting), item)
        }
    }
}
