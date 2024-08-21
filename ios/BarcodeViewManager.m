//
//  BarcodeViewManager.m
//  qrparser
//
//  Created by Bulat on 8/21/24.
//

#import <Foundation/Foundation.h>
#import "React/RCTViewManager.h"
@interface RCT_EXTERN_MODULE(BarcodeViewManager, RCTViewManager)
RCT_EXPORT_VIEW_PROPERTY(onBarcodeRead, RCTDirectEventBlock)
@end
