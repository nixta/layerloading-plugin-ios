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

@implementation AGSMapViewBase (NXTLayerLoading)
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

    NSLog(@"Automatically tracking layer loading status…");
}

-(void)nxtll_addMapLayer:(AGSLayer *)mapLayer
{
//    NSLog(@"Adding map layer: %@", mapLayer);
    
    [mapLayer nxtll_startTracking];
    
    [self nxtll_addMapLayer:mapLayer];
}

-(void)nxtll_removeMapLayer:(AGSLayer *)mapLayer
{
//    NSLog(@"Removing map layer: %@", mapLayer);
    
    [mapLayer nxtll_stopTracking];
    
    [self nxtll_removeMapLayer:mapLayer];
}
@end
