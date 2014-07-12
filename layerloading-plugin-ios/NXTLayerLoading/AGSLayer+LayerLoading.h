//
//  AGSLayer+LayerLoading.h
//  arcgis-layerloading-ios
//
//  Created by Nicholas Furness on 1/15/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import <ArcGIS/ArcGIS.h>

extern NSString *const kLLNotification_LayerLoading;
extern NSString *const kLLNotification_LayerLoaded;
extern NSString *const kLLNotification_LayerNowVisibleByScaleRange;
extern NSString *const kLLNotification_LayerNoLongerVisibleByScaleRange;
extern NSString *const kLLNotification_LayerTrackingStartedForLayer;
extern NSString *const kLLNotification_LayerTrackingStoppedForLayer;

@interface AGSLayer (LayerLoading)
-(void)ll_startTracking;
-(void)ll_stopTracking;
@property (nonatomic, assign, readonly) BOOL ll_isTracking;
@end
