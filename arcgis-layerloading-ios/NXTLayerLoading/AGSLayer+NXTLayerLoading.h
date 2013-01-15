//
//  AGSLayer+NXTLayerLoading.h
//  arcgis-layerloading-ios
//
//  Created by Nicholas Furness on 1/15/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import <ArcGIS/ArcGIS.h>

extern NSString *const kNXTLLNotification_LayerLoading;
extern NSString *const kNXTLLNotification_LayerLoaded;
extern NSString *const kNXTLLNotification_LayerTrackingStartedForLayer;
extern NSString *const kNXTLLNotification_LayerTrackingStoppedForLayer;

@interface AGSLayer (NXTLayerLoading)
-(void)nxtll_startTracking;
-(void)nxtll_stopTracking;
@property (nonatomic, assign, readonly) BOOL nxtll_isTracking;
@end
