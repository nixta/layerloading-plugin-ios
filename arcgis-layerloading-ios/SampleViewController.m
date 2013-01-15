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

@interface SampleViewController () <AGSWebMapDelegate>
@property (weak, nonatomic) IBOutlet AGSMapView *mapView;
@property (nonatomic, retain) AGSWebMap *webMap;
@end

@implementation SampleViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layerLoading:) name:kNXTLLNotification_LayerLoading object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layerLoaded:) name:kNXTLLNotification_LayerLoaded object:nil];

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
    NSLog(@"+++Layer %@ is loading…", layer.name);
}

-(void)layerLoaded:(NSNotification *)n
{
    AGSLayer *layer = n.object;
    NSLog(@"---Layer %@ is loaded…", layer.name);
}

- (IBAction)resetMap:(id)sender {
    [self.mapView reset];
}
- (IBAction)reloadMap:(id)sender {
	// Create a webmap pointing to our ArcGIS.com resource.
	self.webMap = [AGSWebMap webMapWithItemId:@"45895faa12ec4800a681df0b21d11564"//@"a0cdf35893e3467798a0d6a9a8447d8b"
								   credential:nil];
	
	// Set the delegate so we'll know when things fail or succeed
	self.webMap.delegate = self;
    
	// Open the webmap into our AGSMapView
	[self.webMap openIntoMapView:self.mapView];
}
@end
