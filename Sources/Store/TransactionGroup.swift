import Combine
import Foundation
import os.log

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, *)
@_functionBuilder
public struct TransactionSequenceBuilder {
  public static func buildBlock(_ transactions: TransactionConvertible...
  ) -> [AnyTransaction] {
    var result: [AnyTransaction] = []
    var dependencies: TransactionConvertible = NullTransaction()
    for tis in transactions {
      for transaction in tis.transactions {
        transaction.depend(on: dependencies.transactions)
        result.append(transaction)
      }
      dependencies = tis
    }
    return result
  }
}

// MARK: - TransactionCollectionConvertible

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, *)
public protocol TransactionConvertible {
  /// The wrapped transactions.
  var transactions: [AnyTransaction] { get }
}

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, *)
public struct Concurrent: TransactionConvertible {
  /// The wrapped transactions.
  public let transactions: [AnyTransaction]

  public init(@TransactionSequenceBuilder builder: () -> [AnyTransaction]) {
    self.transactions = builder()
  }
  
  public init(transactions: [AnyTransaction]) {
    self.transactions = transactions
  }
}

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, *)
public struct NullTransaction: TransactionConvertible {
  /// The wrapped transactions.
  public var transactions: [AnyTransaction] = []
}

infix operator +

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, *)
extension TransactionConvertible {
  // Transaction1 & Transaction2 results in the two transactions being executed concurrently.
  public static func +(
    lhs: TransactionConvertible,
    rhs: TransactionConvertible
  ) -> TransactionConvertible {
    var transactions = lhs.transactions
    transactions.append(contentsOf: rhs.transactions)
    return Concurrent(transactions: transactions)
  }
}

