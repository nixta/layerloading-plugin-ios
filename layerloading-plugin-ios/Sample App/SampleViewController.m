//
//  DSEUViewController.m
//  Demo1
//
//  Created by Nicholas Furness on 10/24/12.
//  Copyright (c) 2012 Esri. All rights reserved.
//

#import "SampleViewController.h"
#import <ArcGIS/ArcGIS.h>
#import "AGSLayer+LayerLoading.h"
#import "AGSMapView+LayerLoading.h"
#import "NSObject+NFNotificationsProvider.h"

#define kWebMapID @"45895faa12ec4800a681df0b21d11564" // Hurricane Sandy evac layers
//#define kWebMapID @"a0cdf35893e3467798a0d6a9a8447d8b" // DSEU iOS Session Demo WebMap

@interface SampleViewController () <AGSWebMapDelegate, UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet AGSMapView *mapView;
@property (nonatomic, retain) AGSWebMap *webMap;

@property (nonatomic, retain) NSMutableArray *trackedLayers;
@property (nonatomic, retain) NSMutableSet *loadingLayers;

@property (weak, nonatomic) IBOutlet UITableView *layerTableView;

@property (nonatomic, strong) UIColor *loadingColor;
@property (nonatomic, strong) UIColor *loadedColor;
@property (nonatomic, strong) UIColor *outOfRangeColor;
@end

@implementation SampleViewController
#pragma mark - UIView Load and map setup
-(void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    

    

    /// *******************************
    
    [self registerAsListenerForNotifications:@{
        kLLNotification_LayerTrackingStartedForLayer     : strSelector(layerBeingTracked:),
        kLLNotification_LayerTrackingStoppedForLayer     : strSelector(layerNotBeingTracked:),
        kLLNotification_LayerLoading                     : strSelector(layerLoading:),
        kLLNotification_LayerLoaded                      : strSelector(layerLoaded:),
        kLLNotification_LayerNowVisibleByScaleRange      : strSelector(layerBecameVisible:),
        kLLNotification_LayerNoLongerVisibleByScaleRange : strSelector(layerWentOutOfScaleRange:)
    } onObjectOrObjects:nil];
    
    /// *******************************
    
    
    
    
    self.trackedLayers = [NSMutableArray array];
    self.loadingLayers = [NSMutableSet set];
    
    self.loadingColor = [UIColor colorWithRed:0.849 green:0.385 blue:0.427 alpha:1];
    self.loadedColor = [UIColor colorWithRed:0.349 green:0.701 blue:0.325 alpha:1];
    self.outOfRangeColor = [UIColor whiteColor];

	[self reloadMap:nil];
}

// Report an error if the WebMap doesn't load.
-(void)webMap:(AGSWebMap *)webMap didFailToLoadWithError:(NSError *)error
{
	[[[UIAlertView alloc] initWithTitle:@"WebMap Error"
								message:error.localizedDescription
							   delegate:nil
					  cancelButtonTitle:@"OK"
					  otherButtonTitles:nil] show];
	NSLog(@"Couldn't load the WebMap: %@", error);
}

#pragma mark - NOTIFICATION HANDLERS
#pragma mark - Layer Tracking
-(void)layerBeingTracked:(NSNotification *)n
{
    AGSLayer *layer = n.object;
    NSLog(@"  Tracking: %@", layer.name);
    [self.trackedLayers addObject:layer];

    // Add the layer to the UI to show it being tracked.
    NSIndexPath *newPath = [NSIndexPath indexPathForRow:self.trackedLayers.count-1 inSection:0];
    [self.layerTableView insertRowsAtIndexPaths:@[newPath]
                               withRowAnimation:UITableViewRowAnimationTop];
    
    [self updateLayerListTable];
}

-(void)layerNotBeingTracked:(NSNotification *)n
{
    NSInteger oldIndex = [self.trackedLayers indexOfObject:n.object];
    if (oldIndex > -1) {
        AGSLayer *layer = n.object;
        NSLog(@"  Not Tracking: %@", layer.name);
        [self.trackedLayers removeObject:layer];
        [self.loadingLayers removeObject:layer];

        [self.layerTableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:oldIndex inSection:0]]
                                   withRowAnimation:UITableViewRowAnimationTop];
    }
}

#pragma mark - Layer Loading
-(void)layerLoading:(NSNotification *)n
{
    AGSLayer *layer = n.object;
    NSLog(@"    Loading: %@", layer.name);
    [self.loadingLayers addObject:layer];
    [self animateCellForLayer:layer toColor:self.loadingColor];
}

-(void)layerLoaded:(NSNotification *)n
{
    AGSLayer *layer = n.object;
    NSLog(@"    Loaded: %@", layer.name);
    [self.loadingLayers removeObject:layer];
    [self animateCellForLayer:layer toColor:self.loadedColor];
}

#pragma mark - Layer Visibility
-(void)layerBecameVisible:(NSNotification *)n
{
    NSLog(@"Layer %@ now visible.", ((AGSLayer *)n.object).name);
    [self setCell:[self cellForLayer:n.object] alpha:1];
}

-(void)layerWentOutOfScaleRange:(NSNotification *)n
{
    NSLog(@"Layer %@ no longer visible.", ((AGSLayer *)n.object).name);
    UITableViewCell *cell = [self cellForLayer:n.object];
    [self animateCellForLayer:n.object toColor:self.outOfRangeColor];
    [self setCell:cell alpha:0.35];
}

#pragma mark - USER INTERFACE
#pragma mark - Map Load/Reload
-(IBAction)reloadMap:(id)sender {
	// Create a webmap pointing to our ArcGIS.com resource.
	self.webMap = [AGSWebMap webMapWithItemId:kWebMapID credential:nil];

	// Set the delegate so we'll know when things fail or succeed
	self.webMap.delegate = self;
    
	// Open the webmap into our AGSMapView
	[self.webMap openIntoMapView:self.mapView];
}

#pragma mark - UI Updates
-(void)updateLayerListTable
{
    self.layerTableView.hidden = self.trackedLayers.count == 0;
    if (!self.layerTableView.hidden) {
        CGRect newFrame = self.layerTableView.frame;
        newFrame.size.height = 20*self.trackedLayers.count;
        [self.layerTableView setFrame:newFrame];
    }
}

-(void)setCell:(UITableViewCell *)cell alpha:(double)alpha
{
    [UIView animateWithDuration:0.2 animations:^{
        [cell viewWithTag:100].alpha = alpha;
    }];
}

-(void)animateCellForLayer:(AGSLayer *)layer toColor:(UIColor *)targetColor {
    [UIView animateWithDuration:0.2 animations:^{
        [self cellForLayer:layer].backgroundColor = targetColor;
    }];
}

-(UITableViewCell *)cellForLayer:(AGSLayer *)layer
{
    if ([self.trackedLayers containsObject:layer]) {
        return [self.layerTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.trackedLayers indexOfObject:layer] inSection:0]];
    }
    return nil;
}

#pragma mark - UITableView
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.trackedLayers.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AGSLayer *layer = self.trackedLayers[indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"mapLayerCell"];
    UILabel *nameLabel = (UILabel *)[cell viewWithTag:100];
    nameLabel.text = layer.name;
    return cell;
}
@end
