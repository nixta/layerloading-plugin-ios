//
//  DSEUViewController.m
//  Demo1
//
//  Created by Nicholas Furness on 10/24/12.
//  Copyright (c) 2012 Esri. All rights reserved.
//

#import "SampleViewController.h"
#import <ArcGIS/ArcGIS.h>
#import "AGSLayer+NXTLayerLoading.h"
#import "AGSMapView+NXTLayerLoading.h"

#define kWebMapID @"45895faa12ec4800a681df0b21d11564" // Hurricane Sandy evac layers
//#define kWebMapID @"a0cdf35893e3467798a0d6a9a8447d8b" // DSEU iOS Session Demo WebMap

@interface SampleViewController () <AGSWebMapDelegate>
@property (weak, nonatomic) IBOutlet AGSMapView *mapView;
@property (nonatomic, retain) AGSWebMap *webMap;

@property (nonatomic, retain) NSMutableSet *trackedLayers;
@property (nonatomic, retain) NSMutableSet *loadingLayers;
@property (weak, nonatomic) IBOutlet UILabel *trackingLabel;
@end

@implementation SampleViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.trackedLayers = [NSMutableSet set];
    self.loadingLayers = [NSMutableSet set];
	
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(layerLoading:)
                                                 name:kNXTLLNotification_LayerLoading
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(layerLoaded:)
                                                 name:kNXTLLNotification_LayerLoaded
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(layerBeingTracked:)
                                                 name:kNXTLLNotification_LayerTrackingStartedForLayer
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(layerNotBeingTracked:)
                                                 name:kNXTLLNotification_LayerTrackingStoppedForLayer
                                               object:nil];
    
    [self updateLoadingUI];

	[self reloadMap:nil];
}

// Report an error if the WebMap doesn't load.
- (void) webMap:(AGSWebMap *)webMap didFailToLoadWithError:(NSError *)error
{
	[[[UIAlertView alloc] initWithTitle:@"WebMap Error"
								message:error.localizedDescription
							   delegate:nil
					  cancelButtonTitle:@"OK"
					  otherButtonTitles:nil] show];
	NSLog(@"Couldn't load the WebMap: %@", error);
}

-(void)layerLoading:(NSNotification *)n
{
    AGSLayer *layer = n.object;
    NSLog(@"    Loading: %@", layer.name);
    [self.loadingLayers addObject:layer];
    [self updateLoadingUI];
}

-(void)layerLoaded:(NSNotification *)n
{
    AGSLayer *layer = n.object;
    NSLog(@"    Loaded: %@", layer.name);
    [self.loadingLayers removeObject:layer];
    [self updateLoadingUI];
}

-(void)layerBeingTracked:(NSNotification *)n
{
    AGSLayer *layer = n.object;
    NSLog(@"  Tracking: %@", layer.name);
    [self.trackedLayers addObject:layer];
    [self updateLoadingUI];
}

-(void)layerNotBeingTracked:(NSNotification *)n
{
    AGSLayer *layer = n.object;
    NSLog(@"  Not Tracking: %@", layer.name);
    [self.trackedLayers removeObject:layer];
    [self.loadingLayers removeObject:layer];
    [self updateLoadingUI];
}

-(void)updateLoadingUI
{
    NSUInteger layersInScale = 0;
    for (AGSLayer *layer in self.trackedLayers) {
        if (layer.isInScale)
        {
            layersInScale++;
        }
    }
    NSString *feedback = [NSString stringWithFormat:@"%d of %d (%d) layers loading", self.loadingLayers.count, layersInScale, self.trackedLayers.count];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.trackingLabel.text = feedback;
    });
}

- (IBAction)resetMap:(id)sender {
    [self.mapView reset];
}

- (IBAction)reloadMap:(id)sender {
	// Create a webmap pointing to our ArcGIS.com resource.
	self.webMap = [AGSWebMap webMapWithItemId:kWebMapID
								   credential:nil];

	// Set the delegate so we'll know when things fail or succeed
	self.webMap.delegate = self;
    
	// Open the webmap into our AGSMapView
	[self.webMap openIntoMapView:self.mapView];
}
@end
