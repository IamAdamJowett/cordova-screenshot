//
// Screenshot.h
//
// Created by Simon Madine on 29/04/2010.
// Copyright 2010 The Angry Robot Zombie Factory.
// - Converted to Cordova 1.6.1 by Josemando Sobral.
// MIT licensed
//
// Modifications to support orientation change by @ffd8
//

#import <Cordova/CDV.h>
#import "Screenshot.h"

@import Photos;

@implementation Screenshot

@synthesize webView;

- (UIImage *)getScreenshot
{
	UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
	CGRect rect = [keyWindow bounds];
	UIGraphicsBeginImageContextWithOptions(rect.size, YES, 0);
	[keyWindow drawViewHierarchyInRect:keyWindow.bounds afterScreenUpdates:YES];
	UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return img;
}

- (void)saveScreenshot:(CDVInvokedUrlCommand*)command
{
	NSString *filename = [command.arguments objectAtIndex:2];
	NSNumber *quality = [command.arguments objectAtIndex:1];

	NSString *path = [NSString stringWithFormat:@"%@.jpg",filename];
	NSString *jpgPath = [NSTemporaryDirectory() stringByAppendingPathComponent:path];

	UIImage *image = [self getScreenshot];
	NSData *imageData = UIImageJPEGRepresentation(image,[quality floatValue]);
	[imageData writeToFile:jpgPath atomically:NO];

	CDVPluginResult* pluginResult = nil;
	NSDictionary *jsonObj = [ [NSDictionary alloc]
		initWithObjectsAndKeys :
		jpgPath, @"filePath",
		@"true", @"success",
		nil
	];

	pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:jsonObj];
	NSString* callbackId = command.callbackId;
	[self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void) getScreenshotAsURI:(CDVInvokedUrlCommand*)command
{
	NSNumber *quality = command.arguments[0];
	UIImage *image = [self getScreenshot];
	NSData *imageData = UIImageJPEGRepresentation(image,[quality floatValue]);
	NSString *base64Encoded = [imageData base64EncodedStringWithOptions:0];
	NSDictionary *jsonObj = @{
	    @"URI" : [NSString stringWithFormat:@"data:image/jpeg;base64,%@", base64Encoded]
	};
	CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:jsonObj];
	[self.commandDelegate sendPluginResult:pluginResult callbackId:[command callbackId]];
}

- (void)saveToAlbum:(CDVInvokedUrlCommand*)command
{
	NSString *filename = [command.arguments objectAtIndex:0];
    NSString *album = [command.arguments objectAtIndex:1];
    
    __block PHFetchResult *photosAsset;
    __block PHAssetCollection *collection;
    __block PHObjectPlaceholder *placeholder;
    
    UIImage *image = [self getScreenshot];

    // Find the album
    PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
    fetchOptions.predicate = [NSPredicate predicateWithFormat:@"title = %@", album];
    collection = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum
                                                          subtype:PHAssetCollectionSubtypeAny
                                                          options:fetchOptions].firstObject;
    // Create the album
    if (!collection)
    {
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            PHAssetCollectionChangeRequest *createAlbum = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle: album];
            placeholder = [createAlbum placeholderForCreatedAssetCollection];
        } completionHandler:^(BOOL success, NSError *error) {
            if (success)
            {
                PHFetchResult *collectionFetchResult = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[placeholder.localIdentifier]
                                                                                                                options:nil];
                collection = collectionFetchResult.firstObject;
            }
        }];
    }

    // Save to the album
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetChangeRequest *assetRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
        placeholder = [assetRequest placeholderForCreatedAsset];
        photosAsset = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
        PHAssetCollectionChangeRequest *albumChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection
                                                                                                                      assets:photosAsset];
        [albumChangeRequest addAssets:@[placeholder]];
    } completionHandler:^(BOOL success, NSError *error) {
        if (!success) {
            NSLog(@"Error creating album: %@", error);
        }
    }];

    CDVPluginResult* pluginResult = nil;
    NSDictionary *jsonObj = [ [NSDictionary alloc]
        initWithObjectsAndKeys :
        @"true", @"success",
        nil
    ];

    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:jsonObj];
    NSString* callbackId = command.callbackId;
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void)myPluginMethod:(CDVInvokedUrlCommand*)command 
{ 
	// Check command.arguments here. 
	[self.commandDelegate runInBackground:^{ 
		NSString* payload = nil; 
		// Some blocking logic... 
		CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:payload]; 
		// The sendPluginResult method is thread-safe. 
		[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId]; 
	}]; 
}
@end
