//
//  AGSMapView+LayerLoading.m
//  arcgis-layerloading-ios
//
//  Created by Nicholas Furness on 1/10/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import "AGSMapView+LayerLoading.h"
#import "AGSLayer+LayerLoading.h"

#import <objc/runtime.h>

#define kLLAutoTrackLayersKey @"LLAutoTrackLayers"
#define kLLAutoTrackLayersDefault YES

@implementation AGSMapView (LayerLoading)
#pragma mark - Initialization
+(void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Swap some methods around...
        Class myClass = [self class];
        Method a = nil; Method b = nil;
        
        a = class_getInstanceMethod(myClass, @selector(addMapLayer:));
        b = class_getInstanceMethod(myClass, @selector(ll_addMapLayer:));
        method_exchangeImplementations(a, b);
        
        a = class_getInstanceMethod(myClass, @selector(removeMapLayer:));
        b = class_getInstanceMethod(myClass, @selector(ll_removeMapLayer:));
        method_exchangeImplementations(a, b);
    });
}

#pragma mark - Tracking Control Property
-(BOOL)ll_autoTrackLayers
{
    NSNumber *temp = objc_getAssociatedObject(self, kLLAutoTrackLayersKey);
    if (!temp)
    {
        temp = [NSNumber numberWithBool:kLLAutoTrackLayersDefault];
        objc_setAssociatedObject(self, kLLAutoTrackLayersKey, temp, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return temp.boolValue;
}

-(void)setLl_autoTrackLayers:(BOOL)ll_autoTrackLayers
{
    NSNumber *temp = [NSNumber numberWithBool:ll_autoTrackLayers];
    objc_setAssociatedObject(self, kLLAutoTrackLayersKey, temp, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (ll_autoTrackLayers)
    {
        NSLog(@"Automatically tracking layer loading status…");
    }
    else
    {
        NSLog(@"Manually tracking layer loading status…");
    }
}

#pragma mark - Replacement (swizzled) methods
-(void)ll_addMapLayer:(AGSLayer *)mapLayer
{
    // Call the original addMapLayer (which will by now be known as ll_addMapLayer)
    [self ll_addMapLayer:mapLayer];

    if (self.ll_autoTrackLayers)
    {
        [mapLayer ll_startTracking];
    }
}

-(void)ll_removeMapLayer:(AGSLayer *)mapLayer
{
    // Call the original removeMapLayer (which will by now be known as ll_removeMapLayer)
    [self ll_removeMapLayer:mapLayer];

    [mapLayer ll_stopTracking];
}
@end
