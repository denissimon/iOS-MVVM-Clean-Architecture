# ImageSearch
[![Swift Version](https://img.shields.io/badge/Swift-5-F16D39.svg?style=flat)](https://swift.org)
[![Platforms](https://img.shields.io/badge/platform-iOS-lightgrey.svg)](https://developer.apple.com/swift/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/denissimon/ImageSearch/blob/master/LICENSE)

Example iOS app built using the MVVM-C architecture and Flickr API to get images by any tag or search query.

It has three modules: ImageSearch, ImageDetails, HotTags.

#### Architecture concepts used here:
- MVVM using lightweight Observable<T> and Event<T>
- Flow coordinator implemented with closure-based actions
- DIContainer
- Dependency Injection
- Data Binding
- Multiple Storyboards
- Reusable data sources for UITableView and UICollectionView
- Reusable and universal NetworkService based on URLSession
- Codable

#### Built with:
- [SwiftEvents](https://github.com/denissimon/SwiftEvents) - A lightweight library for creating and observing events.
- [Toast-Swift](https://github.com/scalessec/Toast-Swift) - A Swift extension that adds toast notifications to the UIView object class.
- [UAObfuscatedString](https://github.com/UrbanApps/UAObfuscatedString) - A simple category to hide sensitive strings from appearing in your binary.

All necessary supporting code was installed manually, without using a dependency manager.
