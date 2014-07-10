//
//  AGSLayer+LayerLoading.m
//  arcgis-layerloading-ios
//
//  Created by Nicholas Furness on 1/15/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import "AGSLayer+LayerLoading.h"
#import <objc/runtime.h>

#define kLL_LayerIsTrackingKey @"LLLayerIsTracking"
#define kLL_LayerWasInScaleKey @"LLLayerWasInScale"

#define kFeatureLayerTrackingQueryOpKey    @"queryOperation"
#define kFeatureLayerTrackingConnectionKey @"connection"
#define kTiledLayerTrackingQueueCountKey   @"queue.operationCount"

NSString *const kLLNotification_LayerLoading                     = @"LLLayerLoading";
NSString *const kLLNotification_LayerLoaded                      = @"LLLayerLoaded";
NSString *const kLLNotification_LayerNoLongerVisibleByScaleRange = @"LLLayerNoLongerInScale";
NSString *const kLLNotification_LayerNowVisibleByScaleRange      = @"LLLayerNowInScale";
NSString *const kLLNotification_LayerTrackingStartedForLayer     = @"LLLayerTrackingOn";
NSString *const kLLNotification_LayerTrackingStoppedForLayer     = @"LLLayerTrackingOff";

@interface AGSLayer (LayerLoading_Internal)
@property (nonatomic, assign, readwrite) BOOL ll_isTracking;
@property (nonatomic, assign, readwrite) BOOL ll_wasInScale;
@end

@implementation AGSLayer (LayerLoading)
#pragma mark - Tracking Properties
-(BOOL)ll_isTracking
{
    NSNumber *temp = objc_getAssociatedObject(self, kLL_LayerIsTrackingKey);
    if (temp)
    {
        return temp.boolValue;
    }
    return NO;
}

-(void)setLl_isTracking:(BOOL)ll_isTracking
{
    NSNumber *temp = [NSNumber numberWithBool:ll_isTracking];
    
    objc_setAssociatedObject(self, kLL_LayerIsTrackingKey, temp, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    if (ll_isTracking)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kLLNotification_LayerTrackingStartedForLayer object:self];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ll_mapZoomChanged:) name:AGSMapViewDidEndZoomingNotification object:self.mapView];
        [self ll_scaleVisibilityChanged];
    }
    else
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kLLNotification_LayerTrackingStoppedForLayer object:self];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AGSMapViewDidEndZoomingNotification object:self.mapView];
    }
}

-(BOOL)ll_wasInScale
{
    NSNumber *temp = objc_getAssociatedObject(self, kLL_LayerWasInScaleKey);
    if (temp)
    {
        return temp.boolValue;
    }
    return NO;
}

-(void)setLl_wasInScale:(BOOL)newValue
{
    NSNumber *temp = [NSNumber numberWithBool:newValue];
    
    objc_setAssociatedObject(self, kLL_LayerWasInScaleKey, temp, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(void)ll_mapZoomChanged:(NSNotification *)notification
{
    [self ll_checkInScale];
}

-(void)ll_checkInScale
{
    if (self.ll_wasInScale != self.isInScale) {
        [self ll_scaleVisibilityChanged];
    }
}

#pragma mark - Tracking Control
-(void)ll_startTracking
{
    self.ll_wasInScale = NO;
    
    if ([self isKindOfClass:[AGSFeatureLayer class]])
    {
        // Feature Layer
        AGSFeatureLayer *fl = (AGSFeatureLayer *)self;
        
        [fl addObserver:self
             forKeyPath:kFeatureLayerTrackingQueryOpKey
                options:NSKeyValueObservingOptionNew + NSKeyValueObservingOptionInitial + NSKeyValueObservingOptionOld
                context:nil];
        
        self.ll_isTracking = YES;
    }
    else if ([self respondsToSelector:@selector(queue)])
    {
        // Tiled Layer
        [self addObserver:self
            forKeyPath:kTiledLayerTrackingQueueCountKey
               options:NSKeyValueObservingOptionNew + NSKeyValueObservingOptionInitial + NSKeyValueObservingOptionOld
               context:nil];

        self.ll_isTracking = YES;
    }
    else
    {
        // Not expecting to get here.
        NSLog(@"**** Cannot track loading on this kind of layer: %@", self);
        self.ll_isTracking = NO;
    }
}

-(void)ll_stopTracking
{
    if ([self isKindOfClass:[AGSFeatureLayer class]])
    {
        id qOp = [self performSelector:@selector(queryOperation)];
        
        if (qOp)
        {
            // Remove these lines and you'll get a KVO warning when the layer is removed.
            //
            // Shouldn't the KVO below handle removing this observer?
            // Probably, yes, but doubtless when this layer is removed then internally
            // it's nulling the iVar rather than nulling the property, and so bypassing KVO.
            //
            // Just a hunch.
            [qOp removeObserver:self forKeyPath:kFeatureLayerTrackingConnectionKey];
        }
        
        [self removeObserver:self forKeyPath:kFeatureLayerTrackingQueryOpKey];
    }
    else if ([self respondsToSelector:@selector(queue)])
    {
        [self removeObserver:self forKeyPath:kTiledLayerTrackingQueueCountKey];
    }
    else
    {
        // Not expecting to get here.
        NSLog(@"**** Cannot track loading on this kind of layer: %@", self);
    }
    
    self.ll_isTracking = NO;
}

#pragma mark - Tracking Logic
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:kTiledLayerTrackingQueueCountKey])
    {
        // This is either an AGSDynamicLayer or an AGSTiledLayer
        NSInteger newCount = [(NSNumber *)[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        if ([change objectForKey:NSKeyValueChangeOldKey] == nil)
        {
            // OldKey was nil: Layer just getting set up.
            if (newCount > 0)
            {
                NSLog(@"Unexpected start to layer load");
                [self ll_layerLoaded];
            }
        }
        else
        {
            // OldKey was not nil: Layer is changing its operation count...
            NSInteger oldCount = [(NSNumber *)[change objectForKey:NSKeyValueChangeOldKey] integerValue];
            
            if (oldCount == 0 && newCount > 0)
            {
                // Just started loading
                [self ll_layerLoading];
            }
            else if (oldCount > 0 && newCount == 0)
            {
                // Just finished loading
                [self ll_layerLoaded];
            }
        }
    }
    else if ([keyPath isEqualToString:kFeatureLayerTrackingQueryOpKey])
    {
        // The following is based off observation and experiment. It could be incomplete:
        //
        // In this case we have a feature layer and are inspecting its queryOperation
        // The queryOperation is nil unless the featurelayer is getting ready to ask
        // for more features. When it actually asks for more, it'll set it's connection
        // property to non-nil, so we'll watch for that.
        NSOperation *oldQueryOperation = [change objectForKey:NSKeyValueChangeOldKey];
        NSOperation *newQueryOperation = [change objectForKey:NSKeyValueChangeNewKey];
        if (oldQueryOperation != newQueryOperation)
        {
            if (oldQueryOperation != nil &&
                oldQueryOperation != (id)[NSNull null])
            {
                // The queryOperation is being nilled, so let's stop observing it's connection.
                [oldQueryOperation removeObserver:self forKeyPath:kFeatureLayerTrackingConnectionKey];
            }
            
            if (newQueryOperation != nil &&
                newQueryOperation != (id)[NSNull null])
            {
                // A new queryOperation exists, so let's *start* watching its connection.
                [newQueryOperation addObserver:self
                        forKeyPath:kFeatureLayerTrackingConnectionKey
                           options:NSKeyValueObservingOptionNew + NSKeyValueObservingOptionInitial + NSKeyValueObservingOptionOld
                           context:nil];
                // Note, this doesn't mean it's loading yet, just that it's getting ready to load...
            }
        }
    }
    else if ([keyPath isEqualToString:kFeatureLayerTrackingConnectionKey])
    {
        // This is the connection on the queryOperation subclass.
        NSURLConnection *oldConnection = [change objectForKey:NSKeyValueChangeOldKey];
        NSURLConnection *newConnection = [change objectForKey:NSKeyValueChangeNewKey];
        
        if (newConnection != nil &&
            newConnection != (id)[NSNull null])
        {
            // Went from Not Loading to Loading
            [self ll_layerLoading];
        }
        else
        {
            if (oldConnection &&
                oldConnection != (id)[NSNull null])
            {
                // Went from Loading to Not Loading (aka Loaded)
                [self ll_layerLoaded];
            }
        }
    }
}

#pragma mark - Notification Generation
-(void)ll_scaleVisibilityChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:self.isInScale?kLLNotification_LayerNowVisibleByScaleRange:kLLNotification_LayerNoLongerVisibleByScaleRange object:self];
        self.ll_wasInScale = self.isInScale;
    });
}

-(void)ll_layerLoading
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kLLNotification_LayerLoading object:self];
    });
}

-(void)ll_layerLoaded
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kLLNotification_LayerLoaded object:self];
    });
}
@end
