//
//  BarcodeViewManager.swift
//  qrparser
//
//  Created by Bulat on 8/21/24.
//

import Foundation

@objc(BarcodeViewManager)
class BarcodeViewManager : RCTViewManager {
  override func view() -> UIView! {
    return BarcodeView()
  }
  
  override static func requiresMainQueueSetup() -> Bool {
    return true
  }
}
