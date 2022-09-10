//
//  AppGroup.swift
//  Advice
//
//  Created by Arin Asawa on 3/19/21.
//

import Foundation

public enum AppGroup: String {
  case advice = "group.com.arinasawa.storedAdviceData"

  public var containerURL: URL {
    switch self {
    case .advice:
      return FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: self.rawValue)!
    }
  }
}
