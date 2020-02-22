//
//  SwiftEvents.swift
//  https://github.com/denissimon/SwiftEvents
//
//  Created by Denis Simon on 05/29/2019.
//  Copyright © 2019 SwiftEvents. All rights reserved.
//

import Foundation
#if os(Linux)
import Dispatch
#endif

/// A type-safe Event with built-in security.
final public class Event<T> {
    
    private var subscribers = [EventSubscription<T>]()
    
    private let notificationQueue = DispatchQueue(label: "com.swift.events.dispatch.queue", attributes: .concurrent)
    
    /// The number of subscribers to the Event.
    public var subscribersCount: Int {
        return getSubscribers().count
    }
    
    /// The number of times the Event has been triggered.
    private var _triggersCount = Int()
    
    public var triggersCount: Int {
        return getTriggersCount()
    }
    
    public init() {}
    
    /// Adds a new Event subscriber.
    ///
    /// - Parameter target: The target object that subscribes to the Event.
    /// - Parameter queue: The queue in which the handler should be executed when the Event triggers.
    /// - Parameter handler: The closure you want executed when the Event triggers.
    public func addSubscriber<O: AnyObject>(target: O, queue: DispatchQueue? = nil, handler: @escaping (O, T) -> ()) {
        
        let magicHandler: (T) -> () = { [weak target] data in
            if let target = target {
                handler(target, data)
            }
        }
        
        let wrapper = EventSubscription(target: target, queue: queue, handler: magicHandler)
        
        notificationQueue.async(flags: .barrier) {
            self.subscribers.append(wrapper)
        }
    }
    
    /// Triggers the Event, calls all handlers.
    ///
    /// - Parameter data: The data to trigger the Event with.
    public func trigger(_ data: T) {
        notificationQueue.async(flags: .barrier) {
            self._triggersCount += 1
        }
        
        let subscribersDict = getSubscribers()
        
        for subscriber in subscribersDict {
            if subscriber.target != nil {
                callHandler(on: subscriber.queue, data: data, handler: subscriber.handler)
            } else {
                // Removes the subscriber when it is deallocated.
                removeSubscriber(id: subscriber.id)
            }
        }
    }
    
    /// Executes the handler with the provided data and parameters.
    private func callHandler(on queue: DispatchQueue?, data: T, handler: @escaping (T) -> ()) {
        guard let queue = queue else {
            handler(data)
            return
        }
        queue.async {
            handler(data)
        }
    }
    
    /// Removes a specific subscriber from the Event subscribers.
    ///
    /// - Parameter id: The id of the subscriber.
    private func removeSubscriber(id: ObjectIdentifier) {
        notificationQueue.async(flags: .barrier) {
            self.subscribers = self.subscribers.filter { $0.id != id }
        }
    }
    
    /// Removes a specific subscriber from the Event subscribers.
    ///
    /// - Parameter target: The target object that subscribes to the Event.
    public func removeSubscriber(target: AnyObject) {
        removeSubscriber(id: ObjectIdentifier(target))
    }
    
    /// Removes all subscribers on this instance.
    public func removeAllSubscribers() {
        notificationQueue.async(flags: .barrier) {
            self.subscribers.removeAll()
        }
    }
    
    /// Resets the number of times the Event has been triggered.
    public func resetTriggersCount() {
        notificationQueue.async(flags: .barrier) {
            self._triggersCount = 0
        }
    }
    
    private func getSubscribers() -> [EventSubscription<T>] {
        var result = [EventSubscription<T>]()
        notificationQueue.sync {
            result = subscribers
        }
        return result
    }
    
    private func getTriggersCount() -> Int {
        var result = Int()
        notificationQueue.sync {
            result = _triggersCount
        }
        return result
    }
}

/// Wrapper that contains information related to a subscription.
fileprivate struct EventSubscription<T> {
    weak var target: AnyObject?
    let queue: DispatchQueue?
    let handler: (T) -> ()
    let id: ObjectIdentifier
    
    init(target: AnyObject, queue: DispatchQueue?, handler: @escaping (T) -> ()) {
        self.target = target
        self.queue = queue
        self.handler = handler
        id = ObjectIdentifier(target)
    }
}

/// For KVO and bindings functionality.
final public class Observable<T> {
    public let didChanged = Event<(new: T, old: T)>()
    
    public var value: T {
        didSet {
            didChanged.trigger((new: value, old: oldValue))
        }
    }
    
    public init(_ v: T) {
        value = v
    }
}

/// Helper operator to trigger Event data.
infix operator <<<
public func <<< <T> (left: Observable<T>, right: @autoclosure () -> T) {
    left.value = right()
}
