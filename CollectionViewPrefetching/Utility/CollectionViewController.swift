
import UIKit

//MARK: - Style
public struct CollectionViewStyle {
    public var backgroundColor: UIColor
    public var sectionInset: UIEdgeInsets
    public var cellMinimumMargin: CGFloat
    public var showScrollIndicator: Bool
}

extension CollectionViewStyle {
    
    public static let basic = CollectionViewStyle()
    
    public init(sectionInset: UIEdgeInsets = .zero,
                cellMinimumMargin: CGFloat = 0,
                backgroundColor: UIColor = .white,
                showScrollIndicator: Bool = false) {
        self.sectionInset = sectionInset
        self.cellMinimumMargin = cellMinimumMargin
        self.backgroundColor = backgroundColor
        self.showScrollIndicator = showScrollIndicator
    }
}

extension CollectionViewStyle {
    
    public func flowLayout(axis: UICollectionView.ScrollDirection) -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = axis
        layout.minimumInteritemSpacing = cellMinimumMargin
        layout.minimumLineSpacing = cellMinimumMargin
        layout.sectionInset = sectionInset
        return layout
    }
}

//MARK: - Layout
public struct CollectionViewLayout<Item> {
    public var axis: UICollectionView.ScrollDirection
    public var columns: Int
    public var lengthCompute: (_ remainingLength: CGFloat, Item) -> CGFloat
    
    public init(axis: UICollectionView.ScrollDirection,
                columns: Int,
                lengthCompute: @escaping (_ remainingLength: CGFloat, Item) -> CGFloat) {
        self.axis = axis
        self.columns = columns
        self.lengthCompute = lengthCompute
    }
}


extension CollectionViewLayout {
    public func pullback<Root>(_ transform: @escaping (Root) -> (Item)) -> CollectionViewLayout<Root> {
        return CollectionViewLayout<Root>(
            axis: self.axis,
            columns: self.columns,
            lengthCompute: { self.lengthCompute($0, transform($1)) }
        )
    }
    
    public func reSizing(origin: CGFloat, _ stretching: @escaping (CGFloat) -> CGFloat) -> CollectionViewLayout<Item> {
        return CollectionViewLayout<Item>(
            axis: self.axis,
            columns: self.columns,
            lengthCompute: { stretching(self.lengthCompute($0, $1)) }
        )
    }
}

extension CollectionViewLayout {
    public static func ratio(_ ratio: CGFloat, axis: UICollectionView.ScrollDirection, columns: Int) -> CollectionViewLayout {
        return .init(axis: axis, columns: columns) { length, _ in floor(length * ratio) }
    }
    
    public static func constant(_ value: CGFloat, axis: UICollectionView.ScrollDirection, columns: Int) -> CollectionViewLayout {
        return .init(axis: axis, columns: columns) { _, _ in value }
    }
}

extension CollectionViewLayout where Item == String {
    public static func fit(axis: UICollectionView.ScrollDirection,
                           columns: Int,
                           font: UIFont,
                           style: NSParagraphStyle? = nil,
                           margin: UIEdgeInsets = .zero) -> CollectionViewLayout
    {
        return .init(axis: axis, columns: columns) { length, string in
            switch axis {
            case .vertical:
                let width = length - (margin.left + margin.right)
                let height = string.sizeFitWidth(width, font: font, style: style).height
                return height + (margin.top + margin.bottom)
            case .horizontal:
                let height = length - (margin.top + margin.bottom)
                let width = string.sizeFitHeight(height, font: font, style: style).width
                return width + (margin.left + margin.right)
            @unknown default:
                fatalError()
            }
        }
    }
}

extension CollectionViewLayout where Item == UIImage {
    public static func scale(axis: UICollectionView.ScrollDirection, columns: Int) -> CollectionViewLayout<UIImage> {
        return .init(axis: axis, columns: columns) { length, image in
            switch axis {
            case .vertical:
                return image.size.scaleWidth(to: length).height
            case .horizontal:
                return image.size.scaleHeight(to: length).width
            @unknown default:
                fatalError()
            }
        }
    }
}


// MARK: - Config
public struct CollectionViewConfig<Item, Cell: UICollectionViewCell> {
    public let style: CollectionViewStyle
    public let layout: CollectionViewLayout<Item>
    public let dequeueConfig: DequeueConfig<Item, Cell>
    
    public init(
        style: CollectionViewStyle,
        layout: CollectionViewLayout<Item>,
        dequeueConfig: DequeueConfig<Item, Cell>)
    {
        self.style = style
        self.layout = layout
        self.dequeueConfig = dequeueConfig
    }
}

extension CollectionViewConfig {
    public func pullback<Root>(_ transform: @escaping (Root) -> (Item)) -> CollectionViewConfig<Root, Cell> {
        return CollectionViewConfig<Root, Cell>(
            style: style,
            layout: layout.pullback(transform),
            dequeueConfig: dequeueConfig.pullback(transform)
        )
    }
}

extension CollectionViewConfig {
    
    public var flowLayout: UICollectionViewFlowLayout {
        return style.flowLayout(axis: layout.axis)
    }
    
    public var size: (_ viewWidth: CGFloat, Item) -> CGSize {
        return { baseLineLength, item in
            let padding = self.layout.axis == .horizontal
                ? self.style.sectionInset.verticalSpacing
                : self.style.sectionInset.horizontalSpacing
            
            let spacing = padding + CGFloat(self.layout.columns - 1) * self.style.cellMinimumMargin
            let remaining = floor((baseLineLength - spacing) / CGFloat(self.layout.columns))
            let computedLength = self.layout.lengthCompute(remaining, item)
            
            return self.layout.axis == .horizontal
                ? CGSize(width: computedLength, height: remaining)
                : CGSize(width: remaining, height: computedLength)
        }
    }
}


//MARK: CollectionViewController
public final class CollectionViewController<Item, Cell: UICollectionViewCell>: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    public private(set) var items: [Item] {
        didSet {
            collectionView?.reloadData()
        }
    }
    
    public let cellIdentifier: String
    public let configureCell: (Item, Cell) -> ()
    public let size: (_ viewWidth: CGFloat, Item) -> CGSize
    public var didSelect: (_ index: Int, Item) -> ()
    
    private let config: CollectionViewConfig<Item, Cell>
    private let axis: UICollectionView.ScrollDirection
    
    // MARK: Initializer
    public convenience init(items: [Item],
                            config: CollectionViewConfig<Item, Cell>,
                            didSelectItem: @escaping (Item) -> ())
    {
        self.init(items: items, config: config) { _, item in
            didSelectItem(item)
        }
    }
    
    public init(items: [Item],
                config: CollectionViewConfig<Item, Cell>,
                didSelect: @escaping (_ index: Int, Item) -> () = { _, _ in })
    {
        
        self.items = items
        self.cellIdentifier = config.dequeueConfig.identifier
        self.configureCell = config.dequeueConfig.configure
        self.size = config.size
        self.didSelect = didSelect
        self.axis = config.layout.axis
        self.config = config
        
        super.init(collectionViewLayout: config.flowLayout)
        
        guard let collectionView = collectionView else { return }
        collectionView.backgroundColor = config.style.backgroundColor
        collectionView.showsVerticalScrollIndicator = config.style.showScrollIndicator
        collectionView.showsHorizontalScrollIndicator = config.style.showScrollIndicator
        collectionView.register(config: config.dequeueConfig)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Public Method
    public func selectItem(at index: Int) {
        let indexPath = IndexPath(item: index, section: 0)
        collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .init())
        didSelect(indexPath.row, items[indexPath.row])
    }
    
    public func reload(items: [Item]) {
        self.items = items
        collectionView?.reloadData()
    }
    
    // MARK: UICollectionViewDataSource
    public override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    public override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! Cell
        configureCell(items[indexPath.row], cell)
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    public override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        didSelect(indexPath.row, items[indexPath.row])
    }
    
    // MARK: UICollectionViewDelegateFlowLayout
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let length = axis == .vertical ? collectionView.frame.width : collectionView.frame.height
        return size(length, items[indexPath.row])
    }
}
