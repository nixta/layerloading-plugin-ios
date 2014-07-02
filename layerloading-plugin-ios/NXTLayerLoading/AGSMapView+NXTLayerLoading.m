//
//  AGSMapView+NXTLayerLoading.m
//  arcgis-layerloading-ios
//
//  Created by Nicholas Furness on 1/10/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import "AGSMapView+NXTLayerLoading.h"
#import "AGSLayer+NXTLayerLoading.h"

#import <objc/runtime.h>

#define kNXTLLAutoTrackLayersKey @"NXTLLAutoTrackLayers"
#define kNXTLLAutoTrackLayersDefault YES

@implementation AGSMapView (NXTLayerLoading)
+(void)load
{
    // Swap some methods around...
    Class swap = [self class];
    Method a = nil; Method b = nil;

    a = class_getInstanceMethod(swap, @selector(addMapLayer:));
    b = class_getInstanceMethod(swap, @selector(nxtll_addMapLayer:));
    method_exchangeImplementations(a, b);

    a = class_getInstanceMethod(swap, @selector(removeMapLayer:));
    b = class_getInstanceMethod(swap, @selector(nxtll_removeMapLayer:));
    method_exchangeImplementations(a, b);
}

-(BOOL)nxtll_autoTrackLayers
{
    NSNumber *temp = objc_getAssociatedObject(self, kNXTLLAutoTrackLayersKey);
    if (!temp)
    {
        temp = [NSNumber numberWithBool:kNXTLLAutoTrackLayersDefault];
        objc_setAssociatedObject(self, kNXTLLAutoTrackLayersKey, temp, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return temp.boolValue;
}

-(void)setNxtll_autoTrackLayers:(BOOL)nxtll_autoTrackLayers
{
    NSNumber *temp = [NSNumber numberWithBool:nxtll_autoTrackLayers];
    objc_setAssociatedObject(self, kNXTLLAutoTrackLayersKey, temp, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (nxtll_autoTrackLayers)
    {
        NSLog(@"Automatically tracking layer loading status…");
    }
    else
    {
        NSLog(@"Manually tracking layer loading status…");
    }
}

-(void)nxtll_addMapLayer:(AGSLayer *)mapLayer
{
    if (self.nxtll_autoTrackLayers)
    {
        [mapLayer nxtll_startTracking];
    }
    
    // Call the original addMapLayer (which will by now be known as nxtll_addMapLayer)
    [self nxtll_addMapLayer:mapLayer];
}

-(void)nxtll_removeMapLayer:(AGSLayer *)mapLayer
{
    [mapLayer nxtll_stopTracking];
    
    // Call the original removeMapLayer (which will by now be known as nxtll_removeMapLayer)
    [self nxtll_removeMapLayer:mapLayer];
}
@end
