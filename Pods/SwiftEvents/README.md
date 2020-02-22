SwiftEvents
===========

[![Swift](https://img.shields.io/badge/Swift-5.1-orange.svg?style=flat)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS%20%7C%20Linux-lightgrey.svg)](https://developer.apple.com/swift/)

SwiftEvents is a lightweight library for creating and observing events. It's type safe, thread safe and with memory safety. It has functionality of `delegation`, `NotificationCenter`, `key-value observing (KVO)` and `bindings` in one simple API.

Features:

- [x] Type Safety: the concrete type value is delivered to the subscriber without the need for downcasting

- [x] Thread Safety: you can `addSubscriber`, `trigger`, `removeSubscriber` from any thread without issues

- [x] Memory Safety: automatic preventing retain cycles and memory leaks (with no need to specify `[weak self]` in closures); as well as automatic removal of subscribers when they are deallocated 

- [x] Comprehensive unit test coverage

Installation
------------

#### CocoaPods

To install SwiftEvents using [CocoaPods](https://cocoapods.org), add this line to your `Podfile`:

```ruby
pod 'SwiftEvents', '~> 1.1.1'
```

#### Carthage

To install SwiftEvents using [Carthage](https://github.com/Carthage/Carthage), add this line to your `Cartfile`:

```
github "denissimon/SwiftEvents"
```

#### Swift Package Manager

To install SwiftEvents using the [Swift Package Manager](https://swift.org/package-manager), add it to your `Package.swift` file:

```swift
dependencies: [
    .Package(url: "https://github.com/denissimon/SwiftEvents.git", from: "1.1.1")
]
```

#### Manual

Copy `SwiftEvents.swift` into your project.

Usage
-----

### Delegation functionality

With SwiftEvents, such a `one-to-one` connection can be done in just two steps:

1. Create an Event for the publisher
2. Subscribe to the Event

Example:

```swift
import Foundation
import SwiftEvents

// The publisher
class MyModel {
    
    let didDownloadEvent = Event<UIImage?>()
    
    func downloadImage(for url: URL) {
        download(url: url) { image in
            self.didDownloadEvent.trigger(image)
        }
    }
}
```

```swift
import UIKit

// The subscriber
class MyViewController: UIViewController {

    let model = MyModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        model.didDownloadEvent.addSubscriber(target: self, handler: { (self, image) in
            if let image = image {
                self.performUpdate(image)
            }
        })
    }
    
    func updateImage() {
        model.downloadImage(for: /* image url */)
    }
}
```

You can use the Event with any complex type, including multiple values like `(UIImage, Int)?`. You can also create several events (didDownloadEvent, onHTTPErrorEvent, etc), and trigger only what is needed.

### NotificationCenter functionality

If notifications must be `one-to-many`, or two objects that need to be connected are too far apart, SwiftEvents can be used in three steps:

1. Create an EventService
2. Create Events which will be held by EventService
3. Subscribe to the appropriate Event

Example:

```swift
import SwiftEvents

public class EventService {
    
    public static let get = EventService()
    
    private init() {}
    
    // Events
    public let onDataUpdate = Event<String?>()
}
```

```swift
class Controller1 {
    
    init() {
        EventService.get.onDataUpdate.addSubscriber(target: self, handler: { (self, data) in
            print("Controller1: '\(data)'")
        })
    }
}
```

```swift
class Controller2 {
    
    init() {
        EventService.get.onDataUpdate.addSubscriber(target: self, handler: { (self, data) in
            print("Controller2: '\(data)'")
        })
    }
}
```

```swift
class DataModel {
    
    private(set) var data: String? {
        didSet {
            EventService.get.onDataUpdate.trigger(data)
        }
    }
    
    func requestData() {
        // requesting code goes here
        data = "some data"
    }
}
```

```swift
let sub1 = Controller1()
let sub2 = Controller2()
let pub = DataModel()
pub.requestData()
// => Controller1: 'some data'
// => Controller2: 'some data'
```

### KVO and bindings functionality

Just two steps again:

1. Replace the `Type` of property to observe with the `Observable<Type>`
2. Subscribe to the `didChanged` Event

Example:

```swift
import Foundation
import SwiftEvents

class ViewModel {
    
    var infoLabel: Observable<String>

    init() {
        infoLabel = Observable<String>("last saved value")
    }

    func set(newValue: String) {
        infoLabel.value = newValue
    }
}
```

```swift
import UIKit

class View: UIViewController {
    
    var viewModel = ViewModel()

    @IBOutlet weak var infoLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        infoLabel.text = viewModel.infoLabel.value
        
        viewModel.infoLabel.didChanged.addSubscriber(target: self, handler: { (self, value) in
            self.infoLabel.text = value.new
        })
    }
}
```

In this MVVM example, every time the ViewModel changes the value of observable property `infoLabel`, the View is notified with new and old values and updates the `infoLabel.text`.

You can use the infix operator <<< to set a new value for an observable property:

```swift
infoLabel <<< newValue
```

Properties of any class or struct can be observable.

### Advanced topics

#### Manual removal of a subscriber

A subscriber can be removed from the Event subscribers manually:

```swift
func startSubscription() {
    someEvent.addSubscriber(target: self, handler: { (self, result) in
        print(result)
    })
}

func cancelSubscription() {
    someEvent.removeSubscriber(target: self)
}
```

#### Removal of all subscribers

To remove all Event subscribers:

```swift
someEvent.removeAllSubscribers()
```

#### subscribersCount

To get the number of subscribers to the Event:

```swift
let subscribersCount = someEvent.subscribersCount
```

#### triggersCount

To get the number of times the Event has been triggered:

```swift
let triggersCount = someEvent.triggersCount
```

#### Reset of triggersCount

To reset the number of times the Event has been triggered:

```swift
someEvent.resetTriggersCount()
```

#### queue: DispatchQueue

By default, a subscriber's handler is executed on the thread that triggers the Event. To change the default behaviour, you can set this parameter when adding a subscriber:

```swift
// This executes the subscriber's handler on the main queue
someEvent.addSubscriber(target: self, queue: .main, handler: { (self, data) in
    self.updateUI(data)
})
```

#### One-time notification

To remove a subscriber from the Event subscribers after a single notification:

```swift
// The handler of this subscriber will be executed only once
someEvent.addSubscriber(target: self, handler: { (self, data) in
    self.useData(data)
    self.someEvent.removeSubscriber(target: self)
})
```

License
-------

Licensed under the [MIT license](https://github.com/denissimon/SwiftEvents/blob/master/LICENSE)
