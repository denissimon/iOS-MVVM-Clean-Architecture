//
//  SwiftEvents.swift
//  ImageSearch
//
//  Created by Denis Simon on 02/19/2020.
//

import Foundation

protocol Unsubscribable: AnyObject {
    func unsubscribe(_ target: AnyObject)
}

protocol Unbindable: AnyObject {
    func unbind(_ target: AnyObject)
}

final public class Event<T> {
    
    struct Subscriber<T>: Identifiable {
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
    
    private var subscribers = [Subscriber<T>]()
    
    /// The number of subscribers to the Event
    public var subscribersCount: Int { subscribers.count }
    
    /// The number of times the Event was triggered
    private(set) public var triggersCount = Int()
    
    public init() {}
    
    /// - Parameter target: The target object that subscribes to the Event
    /// - Parameter queue: The queue in which the handler should be executed when the Event triggers
    /// - Parameter handler: The closure you want executed when the Event triggers
    public func subscribe<O: AnyObject>(_ target: O, queue: DispatchQueue? = nil, handler: @escaping (T) -> ()) {
        let subscriber = Subscriber(target: target, queue: queue, handler: handler)
        subscribers.append(subscriber)
    }
    
    /// Triggers the Event, calls all handlers, notifies all subscribers
    ///
    /// - Parameter data: The data to trigger the Event with
    public func notify(_ data: T) {
        triggersCount += 1
        for subscriber in subscribers {
            if subscriber.target != nil {
                callHandler(on: subscriber.queue, data: data, handler: subscriber.handler)
            } else {
                // Removes the subscriber if it is deallocated
                unsubscribe(id: subscriber.id)
            }
        }
    }
    
    /// Executes the handler with provided data
    private func callHandler(on queue: DispatchQueue?, data: T, handler: @escaping (T) -> ()) {
        guard let queue = queue else {
            handler(data)
            return
        }
        queue.async {
            handler(data)
        }
    }
    
    /// - Parameter id: The id of the subscriber
    private func unsubscribe(id: ObjectIdentifier) {
        subscribers = subscribers.filter { $0.id != id }
    }
    
    /// - Parameter target: The target object that subscribes to the Event
    public func unsubscribe(_ target: AnyObject) {
        unsubscribe(id: ObjectIdentifier(target))
    }
    
    public func unsubscribeAll() {
        subscribers.removeAll()
    }
}

final public class Observable<T> {
    
    private let didChanged = Event<T>()
    
    public var value: T {
        didSet {
            didChanged.notify(value)
        }
    }
    
    public init(_ v: T) {
        value = v
    }
}

extension Observable {
    
    /// The number of observers of the Observable
    public var observersCount: Int { didChanged.subscribersCount }
    
    /// The number of times the Observable's value was changed and the Observable was triggered
    public var triggersCount: Int { didChanged.triggersCount }
    
    /// - Parameter target: The target object that binds to the Observable
    /// - Parameter queue: The queue in which the handler should be executed when the Observable's value changes
    /// - Parameter handler: The closure you want executed when the Observable's value changes
    public func bind<O: AnyObject>(_ target: O, queue: DispatchQueue? = nil, handler: @escaping (T) -> ()) {
        didChanged.subscribe(target, queue: queue, handler: handler)
    }
    
    /// - Parameter target: The target object that binds to the Observable
    public func unbind(_ target: AnyObject) {
        didChanged.unsubscribe(target)
    }
    
    public func unbindAll() {
        didChanged.unsubscribeAll()
    }
}

infix operator <<<
public func <<< <T> (left: Observable<T>, right: @autoclosure () -> T) {
    left.value = right()
}

extension Event: Unsubscribable {}
extension Observable: Unbindable {}


/* ****************** Thread-safe Event & Observable ****************** */

final public class EventTS<T> {
    
    struct Subscriber<T>: Identifiable {
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
    
    private var subscribers = [Subscriber<T>]()
    
    fileprivate let serialQueue = DispatchQueue(label: "com.swift.events.dispatch.queue")
    
    /// The number of subscribers to the Event
    public var subscribersCount: Int {
        getSubscribers().count
    }
    
    /// The number of times the Event was triggered
    public var triggersCount: Int {
        getTriggersCount()
    }
    
    private var _triggersCount = Int()
    
    public init() {}
    
    /// - Parameter target: The target object that subscribes to the Event
    /// - Parameter queue: The queue in which the handler should be executed when the Event triggers
    /// - Parameter handler: The closure you want executed when the Event triggers
    public func subscribe<O: AnyObject>(_ target: O, queue: DispatchQueue? = nil, handler: @escaping (T) -> ()) {
        let subscriber = Subscriber(target: target, queue: queue, handler: handler)
        serialQueue.sync {
            self.subscribers.append(subscriber)
        }
    }
    
    /// Triggers the Event, calls all handlers, notifies all subscribers
    ///
    /// - Parameter data: The data to trigger the Event with
    public func notify(_ data: T) {
        serialQueue.sync {
            self._triggersCount += 1
        }
        
        let subscribers = getSubscribers()
        
        for subscriber in subscribers {
            if subscriber.target != nil {
                callHandler(on: subscriber.queue, data: data, handler: subscriber.handler)
            } else {
                // Removes the subscriber if it is deallocated
                unsubscribe(id: subscriber.id)
            }
        }
    }
    
    /// Executes the handler with provided data
    private func callHandler(on queue: DispatchQueue?, data: T, handler: @escaping (T) -> ()) {
        guard let queue = queue else {
            handler(data)
            return
        }
        queue.async {
            handler(data)
        }
    }
    
    /// - Parameter id: The id of the subscriber
    private func unsubscribe(id: ObjectIdentifier) {
        serialQueue.sync {
            self.subscribers = self.subscribers.filter { $0.id != id }
        }
    }
    
    /// - Parameter target: The target object that subscribes to the Event
    public func unsubscribe(_ target: AnyObject) {
        unsubscribe(id: ObjectIdentifier(target))
    }
    
    public func unsubscribeAll() {
        serialQueue.sync {
            self.subscribers.removeAll()
        }
    }
    
    private func getSubscribers() -> [Subscriber<T>] {
        serialQueue.sync {
            self.subscribers
        }
    }
    
    private func getTriggersCount() -> Int {
        serialQueue.sync {
            self._triggersCount
        }
    }
}

final public class ObservableTS<T> {
    
    private let didChanged = EventTS<T>()
    
    public var value: T {
        get {
            didChanged.serialQueue.sync {
                self._value
            }
        }
        set {
            didChanged.serialQueue.sync {
                self._value = newValue
            }
            didChanged.notify(_value)
        }
    }
    
    private var _value: T
    
    public init(_ v: T) {
        _value = v
    }
}

extension ObservableTS {
    
    /// The number of observers of the Observable
    public var observersCount: Int { didChanged.subscribersCount }
    
    /// The number of times the Observable's value was changed and the Observable was triggered
    public var triggersCount: Int { didChanged.triggersCount }
    
    /// - Parameter target: The target object that binds to the Observable
    /// - Parameter queue: The queue in which the handler should be executed when the Observable's value changes
    /// - Parameter handler: The closure you want executed when the Observable's value changes
    public func bind<O: AnyObject>(_ target: O, queue: DispatchQueue? = nil, handler: @escaping (T) -> ()) {
        didChanged.subscribe(target, queue: queue, handler: handler)
    }
    
    /// - Parameter target: The target object that binds to the Observable
    public func unbind(_ target: AnyObject) {
        didChanged.unsubscribe(target)
    }
    
    public func unbindAll() {
        didChanged.unsubscribeAll()
    }
}

public func <<< <T> (left: ObservableTS<T>, right: @autoclosure () -> T) {
    left.value = right()
}

extension EventTS: Unsubscribable {}
extension ObservableTS: Unbindable {}

