# Prefetching Collection View Data

Load data for collection view cells before they are displayed.

## Overview

A collection view displays an ordered collection of cells in customizable layouts. The [`UICollectionViewDataSourcePrefetching`](https://developer.apple.com/documentation/uikit/uicollectionviewdatasourceprefetching) protocol helps provide a smoother user experience by prefetching the data necessary for upcoming collection view cells. When you enable prefetching, the collection view requests the data before it needs to display the cell. When it's time to display the cell, the data is already locally cached.

The image below shows cells outside the bounds of the collection view that have been prefetched.   

![CollectionViewPrefetching.app](Documentation/screenshot.png)

- Note: The storyboard used in this project contains a collection view controller whose collection view has Clips To Bounds disabled. With this configuration, you can visualize the cells before they would normally be displayed.

## Enable Prefetching

The root view controller uses an instance of the [`CustomDataSource`](x-source-tag://CustomDataSource) class to provide data to its [`UICollectionView`](https://developer.apple.com/documentation/uikit/uicollectionview) instance. The `CustomDataSource` class implements the `UICollectionViewDataSourcePrefetching` protocol to begin fetching the data required to populate cells.

``` swift
class CustomDataSource: NSObject, UICollectionViewDataSource, UICollectionViewDataSourcePrefetching {
```
[View in Source](x-source-tag://CustomDataSource)

In addition to assigning the `CustomDataSource` instance to the collection view's [`dataSource`](https://developer.apple.com/documentation/uikit/uicollectionview/1618091-datasource) property, you must also assign it to the [`prefetchDataSource`](https://developer.apple.com/documentation/uikit/uicollectionview/1771768-prefetchdatasource) property.

``` swift
// Set the collection view's data source.
collectionView.dataSource = dataSource

// Set the collection view's prefetching data source.
collectionView.prefetchDataSource = dataSource
```
[View in Source](x-source-tag://SetDataSources)

## Load Data Asynchronously

You use data prefetching when loading data is a slow or expensive process—for example, when fetching data over the network. In these circumstances, perform data loading asynchronously. In this sample, the [`AsyncFetcher`](x-source-tag://AsyncFetcher) class is used to fetch data asynchronously, simulating a network request.

First, implement the [`UICollectionViewDataSourcePrefetching`](https://developer.apple.com/documentation/uikit/uicollectionviewdatasourceprefetching) prefetch method, invoking the appropriate method on the async fetcher:

``` swift
func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
    // Begin asynchronously fetching data for the requested index paths.
    for indexPath in indexPaths {
        let model = models[indexPath.row]
        asyncFetcher.fetchAsync(model.identifier)
    }
}
```
[View in Source](x-source-tag://Prefetching)

- Note: Create your own version of `AsyncFetcher` to fit your requirements. The implementation in this sample makes heavy use of [`Operation`](https://developer.apple.com/documentation/foundation/operation) and [`OperationQueue`](https://developer.apple.com/documentation/foundation/operationqueue), leveraging their ability to handle thread safety and cancellation. It's recommended that you consider a similar approach.

When prefetching is complete, the cell's data is added to the `AsyncFetcher`'s cache, so it's ready to be used when the cell is displayed. The cell's background color changes from white to red when data is available for that cell.

``` swift
/**
 Configures the cell for display based on the model.
 
 - Parameters:
     - data: An optional `DisplayData` object to display.
 
 - Tag: Cell_Config
*/
func configure(with data: DisplayData?) {
    backgroundColor = data?.color
}
```
[View in Source](x-source-tag://Cell_Config)

## Populate Cells for Display

Before populating a cell, the `CustomDataSource` first checks for any prefetched data that it can use. If none is available, the `CustomDataSource` makes a fetch request and the cell is updated in the fetch request's completion handler.

``` swift
func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Cell.reuseIdentifier, for: indexPath) as? Cell else {
        fatalError("Expected `\(Cell.self)` type for reuseIdentifier \(Cell.reuseIdentifier). Check the configuration in Main.storyboard.")
    }
    
    let model = models[indexPath.row]
    let identifier = model.identifier
    cell.representedIdentifier = identifier
    
    // Check if the `asyncFetcher` has already fetched data for the specified identifier.
    if let fetchedData = asyncFetcher.fetchedData(for: identifier) {
        // The data has already been fetched and cached; use it to configure the cell.
        cell.configure(with: fetchedData)
    } else {
        // There is no data available; clear the cell until we've fetched data.
        cell.configure(with: nil)

        // Ask the `asyncFetcher` to fetch data for the specified identifier.
        asyncFetcher.fetchAsync(identifier) { fetchedData in
            DispatchQueue.main.async {
                /*
                 The `asyncFetcher` has fetched data for the identifier. Before
                 updating the cell, check if it has been recycled by the
                 collection view to represent other data.
                 */
                guard cell.representedIdentifier == identifier else { return }
                
                // Configure the cell with the fetched image.
                cell.configure(with: fetchedData)
            }
        }
    }

    return cell
}
```
[View in Source](x-source-tag://CellForItemAt)

## Cancel Unnecessary Fetches

Implement the [`collectionView(_:cancelPrefetchingForItemsAt:)`](https://developer.apple.com/documentation/uikit/uicollectionviewdatasourceprefetching/1771769-collectionview) delegate method to cancel any in-progress data fetches that are no longer required. An example of how to handle this is taken from the sample and shown below.

``` swift
func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
    // Cancel any in-flight requests for data for the specified index paths.
    for indexPath in indexPaths {
        let model = models[indexPath.row]
        asyncFetcher.cancelFetch(model.identifier)
    }
}
```
[View in Source](x-source-tag://CancelPrefetching)
