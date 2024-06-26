# iOS-MVVM-Clean-Architecture
[![Swift Version](https://img.shields.io/badge/Swift-5-F16D39.svg?style=flat)](https://swift.org)
[![Platforms](https://img.shields.io/badge/platform-iOS-lightgrey.svg)](https://developer.apple.com/swift/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/denissimon/iOS-MVVM-Clean-Architecture/blob/master/LICENSE)

Example iOS app designed using MVVM-C and Clean Architecture. Uses Swift Concurrency.

The app retrieves images for any search query or tag via the Flickr API. It has three MVVM modules: ImageSearch, ImageDetails, HotTags.

<table> 
  <tr>
    <td> <img src="Screenshots/1 iOS-MVVM-Clean-Architecture Screen Shot - 2023-12-17.png" width = 252px></td>
    <td> <img src="Screenshots/2 iOS-MVVM-Clean-Architecture Screen Shot - 2023-12-17.png" width = 252px></td>
    <td> <img src="Screenshots/3 iOS-MVVM-Clean-Architecture Screen Shot - 2023-12-17.png" width = 252px></td>
  </tr>
</table>

### Architecture concepts used here

- [MVVM][MVVMLink]
- [Flow coordinator][FlowCoordinatorLink] implemented with closure-based actions
- [Dependency Injection][DIContainerLink], DIContainer
- [Data Binding][DataBindingLink] using the lightweight [Observable\<T\>][ObservableLink]
- [Clean Architecture][CleanArchitectureLink]
- [Explicit Architecture][ExplicitArchitectureLink]
- [Protocol-Oriented Programming][POPLink]
- [Closure-based delegation][ClosureBasedDelegationLink] using the lightweight [Event\<T\>][EventLink]
- [Pure functional transformations][PureFunctionalTransformationsLink]
- [Shared Kernel][SharedKernelLink], delegating entity behavior
- [Codable][CodableLink]
- [Alternative DTO approach][AlternativeDTOApproachLink]

[MVVMLink]: https://github.com/denissimon/iOS-MVVM-Clean-Architecture/tree/master/ImageSearch/Modules/ImagesFeature/ImageSearch
[FlowCoordinatorLink]: https://github.com/denissimon/iOS-MVVM-Clean-Architecture/tree/master/ImageSearch/Coordinator
[DIContainerLink]: https://github.com/denissimon/iOS-MVVM-Clean-Architecture/blob/master/ImageSearch/Coordinator/DIContainer/DIContainer.swift
[ObservableLink]: https://github.com/denissimon/iOS-MVVM-Clean-Architecture/blob/master/ImageSearch/Common/Utils/SwiftEvents.swift#L86
[DataBindingLink]: https://github.com/denissimon/iOS-MVVM-Clean-Architecture/blob/master/ImageSearch/Modules/ImagesFeature/ImageSearch/ViewModel/DefaultImageSearchViewModel.swift
[EventLink]: https://github.com/denissimon/iOS-MVVM-Clean-Architecture/tree/master/ImageSearch/Common/Utils/SwiftEvents.swift
[CleanArchitectureLink]: https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html
[ExplicitArchitectureLink]: https://herbertograca.com/2017/11/16/explicit-architecture-01-ddd-hexagonal-onion-clean-cqrs-how-i-put-it-all-together
[POPLink]: https://www.swiftanytime.com/blog/protocol-oriented-programming-in-swift
[ClosureBasedDelegationLink]: https://github.com/denissimon/iOS-MVVM-Clean-Architecture/blob/master/ImageSearch/Modules/ImagesFeature/HotTags/ViewModel/DefaultHotTagsViewModel.swift
[PureFunctionalTransformationsLink]: https://github.com/denissimon/iOS-MVVM-Clean-Architecture/blob/master/ImageSearch/Data/Repositories/DefaultImageRepository.swift 
[SharedKernelLink]: https://github.com/denissimon/iOS-MVVM-Clean-Architecture/blob/master/ImageSearch/Domain/Services/SharedKernel.swift
[CodableLink]: https://github.com/denissimon/iOS-MVVM-Clean-Architecture/blob/master/ImageSearch/Domain/Entities/Image.swift
[AlternativeDTOApproachLink]: https://medium.com/geekculture/why-we-shouldnt-use-data-transfer-objects-in-swift-38dcef529a66

### Includes

- Reusable and universal [NetworkService][NetworkServiceLink] based on URLSession
- Reusable and universal [SQLite][SQLiteAdapterLink] wrapper around SQLite3
- [Image caching service][ImageCachingServiceLink]
- Advanced error handling
- Unit tests for a number of components from all layers

[NetworkServiceLink]: https://github.com/denissimon/iOS-MVVM-Clean-Architecture/tree/master/ImageSearch/Data/Network/NetworkService
[SQLiteAdapterLink]: https://github.com/denissimon/iOS-MVVM-Clean-Architecture/blob/master/ImageSearch/Data/Storages/SQLite
[ImageCachingServiceLink]: https://github.com/denissimon/iOS-MVVM-Clean-Architecture/blob/master/ImageSearch/Data/Services/DefaultImageCachingService.swift

### Main layers

**Presentation Layer**: _coordinators_, _UI elements / views_, _storyboards_, _view controllers_ and _ViewModels_

**Domain Layer**: _entities_ (or _domain models_), _interfaces_ (for services and repositories) and _domain services_

**Data Layer**: _services_, _entity repositories_, _API/DB interactors_ (or network services and storages) and _adapters_

### Use cases

ImageSearch module:
```swift
* imageService.searchImages(imageQuery)
* imageCachingService.cacheIfNecessary(self.data.value)
* imageCachingService.getCachedImages(searchId: searchId)
```

ImageDetails module:
```swift
* imageService.getBigImage(for: self.image)
```

HotTags module:
```swift
* tagRepository.getHotTags()
```

### Image caching service

[ImageCachingService][ImageCachingServiceLink] implements logic for caching images downloaded from Flickr. This helps keep the app's memory usage under control, since there can be a lot of downloaded images, and without caching, the app could quickly accumulate hundreds of MB of memory used. Downloaded images are cached and read from the cache automatically.

### Reusable components from this project

- [SwiftEvents](https://github.com/denissimon/SwiftEvents) - the easiest way to implement data binding and notifications. Includes Event\<T\> and Observable\<T\>. Has a thread-safe version.
- [URLSessionAdapter](https://github.com/denissimon/URLSessionAdapter) - a Codable wrapper around URLSession for networking
- [SQLiteAdapter](https://github.com/denissimon/SQLiteAdapter) - a simple wrapper around SQLite3

### Requirements

iOS version support: 15.0+. For app versions <= 1.2, iOS version support: 10.0+

Xcode 13.0+, Swift 5.5+
