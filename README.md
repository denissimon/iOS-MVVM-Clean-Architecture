# ImageSearch
[![Swift Version](https://img.shields.io/badge/Swift-5-F16D39.svg?style=flat)](https://swift.org)
[![Platforms](https://img.shields.io/badge/platform-iOS-lightgrey.svg)](https://developer.apple.com/swift/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/denissimon/ImageSearch/blob/master/LICENSE)

A demo iOS app built using the MVVM-C + Storyboards architecture with Swift 5.

This app gets images using Flickr API. It has three modules: ImageSearch, ImageDetails, HotTagsList.

#### Architecture concepts:
- MVVM
- Coordinator
- Multiple Storyboards
- Dependency Injection
- Data Binding
- Event-based communication between classes
- Reusable data sources for UITableView and UICollectionView
- Reusable and universal networking
- Codable

#### Built with:
- [SwiftEvents](https://github.com/denissimon/SwiftEvents) - A lightweight library for creating and observing events.
- [Toast-Swift](https://github.com/scalessec/Toast-Swift) - A Swift extension that adds toast notifications to the UIView object class.
- [UAObfuscatedString](https://github.com/UrbanApps/UAObfuscatedString) - A simple category to hide sensitive strings from appearing in your binary.

The dependency manager is [CocoaPods](https://cocoapods.org). Run `pod update` to update pods.
