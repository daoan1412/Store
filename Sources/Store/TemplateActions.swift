import Foundation
import os.log

// MARK: - Template Actions

public enum KeyPath<M, V> {
  /// A non-optional writeable keyPath.
  case value(keyPath: WritableKeyPath<M, V>)
  /// A optional writeable keyPath.
  case optional(keyPath: WritableKeyPath<M, V?>)
}

/// General-purpose actions that can be applied to any store.
public struct TemplateAction {

  public struct AssignKeyPath<M, V>: ActionProtocol {
    public let keyPath: KeyPath<M, V>
    public let value: V?

    public func reduce(context: TransactionContext<Store<M>, Self>) {
      defer { context.fulfill() }
      context.reduceModel { model in
        _assignKeyPath(object: &model, keyPath: keyPath, value: value)
      }
    }
  }
  
  public struct Filter<M, V: Collection, T>: ActionProtocol where V.Element == T {
    public let keyPath: KeyPath<M, V>
    public let isIncluded: (T) -> Bool
    
    public func reduce(context: TransactionContext<Store<M>, Self>) {
      defer { context.fulfill() }
      context.reduceModel { model in
        _mutateArray(object: &model, keyPath: keyPath) { $0 = $0.filter(isIncluded) }
      }
    }
  }
  
  public struct RemoveAtIndex<M, V: Collection, T>: ActionProtocol where V.Element == T {
    public let keyPath: KeyPath<M, V>
    public let index: Int
    
    public func reduce(context: TransactionContext<Store<M>, Self>) {
      defer { context.fulfill() }
      context.reduceModel { model in
        _mutateArray(object: &model, keyPath: keyPath) { $0.remove(at: index) }
      }
    }
  }
  
  public struct Push<M, V: Collection, T>: ActionProtocol where V.Element == T {
    public let keyPath: KeyPath<M, V>
    public let object: T

    public func reduce(context: TransactionContext<Store<M>, Self>) {
      defer { context.fulfill() }
      context.reduceModel { model in
        _mutateArray(object: &model, keyPath: keyPath) { $0.append(object) }
      }
    }
  }
}

private func _mutateArray<M, V: Collection, T>(
  object: inout M,
  keyPath: KeyPath<M, V>,
  mutate: (inout [T]) -> Void
) where V.Element == T  {
  var value: V
  switch keyPath {
  case .value(let keyPath): value = object[keyPath: keyPath]
  case .optional(let keyPath):
    guard let unwrapped = object[keyPath: keyPath] else { return }
    value = unwrapped
  }
  guard var array = value as? [T] else {
    os_log(.error, log: OSLog.primary, " Arrays are the only collection type supported.")
    return
  }
  mutate(&array)
  // Trivial cast.
  guard let collection = array as? V else { return }
  switch keyPath {
  case .value(let keyPath): object[keyPath: keyPath] = collection
  case .optional(let keyPath): object[keyPath: keyPath] = collection
  }
}

private func _assignKeyPath<M, V>(object: inout M, keyPath: KeyPath<M, V>, value: V?) {
  switch keyPath {
  case .value(let keyPath):
    guard let value = value else { return }
    object[keyPath: keyPath] = value
  case .optional(let keyPath):
    object[keyPath: keyPath] = value
  }
}
