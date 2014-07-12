//
//  AGSMapView+LayerLoading.h
//  arcgis-layerloading-ios
//
//  Created by Nicholas Furness on 1/10/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

// You do not need to reference this .h for the framework to work. It automatically
// hooks itself onto any AGSMapView as long as the source files are compiled into your target.
//
// If you want to disable auto-tracking and control layer tracking manually on a per-layer
// basis, include this and set self.mapView.ll_autoTrackLayer = NO

#import <ArcGIS/ArcGIS.h>

@interface AGSMapView (LayerLoading)
@property (nonatomic, assign) BOOL ll_autoTrackLayers;
@end
