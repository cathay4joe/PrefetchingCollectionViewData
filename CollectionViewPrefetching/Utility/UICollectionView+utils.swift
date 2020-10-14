
import UIKit

extension UICollectionView {
    
    public enum SupplementaryViewKind {
        case header
        case footer
    }
    
    // MARK: - UICollectionViewCell
    public func register<T: UICollectionViewCell>(_ cell: T.Type) where T: ReusableView {
        register(T.self, forCellWithReuseIdentifier: T.reuseIdentifier)
    }
    
    public func registerNib<T: UICollectionViewCell>(_ cell: T.Type) where T: ReusableNibView {
        register(T.nib, forCellWithReuseIdentifier: T.reuseIdentifier)
    }
    
    public func register<Item, Cell: UICollectionViewCell>(config: DequeueConfig<Item, Cell>) {
        switch config.kind {
        case .default:
            register(Cell.self, forCellWithReuseIdentifier: config.identifier)
        case .nib(let nib):
            register(nib(), forCellWithReuseIdentifier: config.identifier)
        case .storyboard:
            break
        }
    }
    
    public func dequeue<T: UICollectionViewCell>(_ cell: T.Type, for indexPath: IndexPath) -> T where T: ReusableView {
        guard let cell = dequeueReusableCell(withReuseIdentifier: T.reuseIdentifier, for: indexPath) as? T else {
            fatalError("cell can't dequeue collectionview cell, maybe forgot to register")
        }
        return cell
    }
    
    // MARK: - UICollectionReusableView
    public func register<T: UICollectionReusableView>(_ view: T.Type, kind: SupplementaryViewKind) where T: ReusableView {
        register(T.self, forSupplementaryViewOfKind: kind.value, withReuseIdentifier: T.reuseIdentifier)
    }
    
    public func registerNib<T: UICollectionReusableView>(_ view: T.Type, kind: SupplementaryViewKind) where T: ReusableNibView {
        register(T.nib, forSupplementaryViewOfKind: kind.value, withReuseIdentifier: T.reuseIdentifier)
    }
    
    public func register<Item, View: UICollectionReusableView>(config: DequeueConfig<Item, View>, kind: SupplementaryViewKind) {
        switch config.kind {
        case .default:
            register(View.self, forSupplementaryViewOfKind: kind.value, withReuseIdentifier: config.identifier)
        case .nib(let nib):
            register(nib(), forSupplementaryViewOfKind: kind.value, withReuseIdentifier: config.identifier)
        case .storyboard:
            break
        }
    }
    
    public func dequeue<T: UICollectionReusableView>(_ view: T.Type, kind: String, for indexPath: IndexPath) -> T where T: ReusableView {
        return dequeueReusableSupplementaryView(ofKind: kind,
                                                withReuseIdentifier: T.reuseIdentifier,
                                                for: indexPath) as! T
    }
}

extension UICollectionView.SupplementaryViewKind {
    public var value: String {
        switch self {
        case .header: return UICollectionView.elementKindSectionHeader
        case .footer: return UICollectionView.elementKindSectionFooter
        }
    }
}
