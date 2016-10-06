#if os(iOS)
import UIKit

// MARK: - Frame Collection View Controller -
//------------------------------------------------------------------------------
/// Displays a collection of frames and their images.
public class FrameCollectionViewController: UICollectionViewController, FrameImageDelegate {
    public enum FrameImageRatio {
        case square
        case `default`
    }

    // MARK: - Public -
    //--------------------------------------------------------------------------
    /// - parameter delegate: This identifies which object is responsible for
    ///             handling frame selection.
    public weak var delegate: FrameCollectionDelegate? = nil

    /// - parameter images: The collection of frame images the controller is
    ///             responsible for displaying. When this value changes, it
    ///             triggers a `reload()` on the collection view.
    public var images: [FrameImage] = [] {
        didSet {
            reload()
        }
    }

    /// - parameter preferredFrameImageRatio: This will determine the ratio of
    ///             frame images in the collection. `square` displays every cell
    ///             with equal width and height (however, meme text may appear
    ///             clipped). `default` will display the cell correctly scaled
    ///             down, preserving the original width and height of the source
    ///             image.
    public var preferredFrameImageRatio: FrameImageRatio = .square

    // MARK: - Computed -
    //--------------------------------------------------------------------------
    /// - parameter hasImages: A convenience accessor for `!images.isEmpty`.
    public final var hasImages: Bool {
        return !images.isEmpty
    }

    /// - parameter flowLayout: A convenience accessor for the collection view's
    ///             layout object.
    var flowLayout: UICollectionViewFlowLayout {
        return collectionView?.collectionViewLayout as! UICollectionViewFlowLayout
    }

    // MARK: - Initialization -
    //--------------------------------------------------------------------------
    public required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }
    public required init() {
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
    }

    // MARK: - Reload -
    //--------------------------------------------------------------------------
    public func reload() {
        DispatchQueue.main.async { [weak self] in
            self?.collectionView?.reloadData()
        }
    }

    // MARK: - Frame Image Delegate -
    //--------------------------------------------------------------------------
    public func frame(_ frame: FrameImage, didUpdateImage image: UIImage) {
        reload()
    }

    public func frame(_ frame: FrameImage, didUpdateMeme meme: UIImage) {
        // Override me
    }
}

// MARK: - Extension, Helpers -
//------------------------------------------------------------------------------
extension FrameCollectionViewController {
    // MARK: - Item Size -
    //--------------------------------------------------------------------------
    public final func imageSize(for frameImage: FrameImage?, `in` collectionView: UICollectionView, itemWidthMultiplier: CGFloat = 1.0) -> CGSize {
        // HACK: Reset multiplier if we're in landscape
        //----------------------------------------------------------------------
        // WARNING: This is a smell (☠️)
        //----------------------------------------------------------------------
        let screenSize = UIScreen.main.bounds.size
        var itemWidthMultiplier = itemWidthMultiplier
        if screenSize.height.isLessThanOrEqualTo(screenSize.width) {
            itemWidthMultiplier = 1.0
        }

        // Calculate
        //----------------------------------------------------------------------
        let maxWidth = collectionView.maxWidth(for: itemsPerRow)

        // Forces a square image when fails
        //----------------------------------------------------------------------
        guard let frameImage = frameImage
            , let image = frameImage.image
            , preferredFrameImageRatio == .`default` else {
                let itemWidth = (maxWidth / CGFloat(itemsPerRow)) / itemWidthMultiplier
                return CGSize(width: itemWidth, height: itemWidth)
        }

        // Use original image ratio
        //----------------------------------------------------------------------
        let imageRatio = maxWidth / image.size.width / max(1.0, (CGFloat(itemsPerRow) / itemWidthMultiplier))
        let imageWidth = image.size.width * imageRatio
        let imageHeight = image.size.height * imageRatio

        return CGSize(width: imageWidth, height: imageHeight)
    }

}

// MARK: - Extension, View Lifecycle -
//------------------------------------------------------------------------------
extension FrameCollectionViewController {
    public override func viewDidLoad() {
        super.viewDidLoad()

        // Collection View
        //--------------------------------------------------------------------------
        collectionView?.backgroundColor = .simpsonsYellow
        collectionView?.alwaysBounceHorizontal = false

        // Cell Types
        //----------------------------------------------------------------------
        collectionView?.register(FrameImageCell.self, forCellWithReuseIdentifier: FrameImageCell.cellIdentifier)

        // Collection Layout
        //----------------------------------------------------------------------
        let inset: CGFloat = 24.0
        let spacing: CGFloat = 24.0
        flowLayout.sectionInset = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
        flowLayout.minimumInteritemSpacing = spacing
        flowLayout.minimumLineSpacing = spacing
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        reload()
    }
}

// MARK: - Extension, Data Source -
//------------------------------------------------------------------------------
extension FrameCollectionViewController {
    public final override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    public final override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }

    public override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return dequeue(frameCellAt: indexPath)
    }

    public override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let frameImage = images[indexPath.row]
        delegate?.frameCollection(self, didSelect: frameImage)
    }

    // MARK: - Dequeue Cell -
    //--------------------------------------------------------------------------
    public func dequeue(frameCellAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: FrameImageCell.cellIdentifier, for: indexPath) as! FrameImageCell

        let image = images[indexPath.row].image
        cell.imageView.image = image

        return cell
    }
}

// MARK: - Extension, Flow Layout Delegate -
//------------------------------------------------------------------------------
extension FrameCollectionViewController: UICollectionViewDelegateFlowLayout {
    public var itemsPerRow: Int {
        return 2
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return imageSize(for: images[indexPath.row], in: collectionView)
    }
}

// MARK: - Frame Collection Delegate -
//------------------------------------------------------------------------------
public protocol FrameCollectionDelegate: class {
    func frameCollection(_ : FrameCollectionViewController, didSelect frameImage: FrameImage)
}

// MARK: - Extension, Collection View
//------------------------------------------------------------------------------
extension UICollectionView {
    public final func maxWidth(for itemCount: Int) -> CGFloat {
        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else {
            fatalError("Layout must be an instance of \(UICollectionViewFlowLayout.self)")
        }
        return frame.width
            .subtracting(flowLayout.sectionInset.left)
            .subtracting(flowLayout.sectionInset.right)
            .subtracting(flowLayout.minimumInteritemSpacing * (max(1.0, CGFloat(itemCount).subtracting(1.0))))
    }

    public final func numberOfItems(in section: Int = 0) -> Int {
        return dataSource?.collectionView(self, numberOfItemsInSection: section) ?? 0
    }
}
#endif
