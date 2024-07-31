//
//  FileTableViewController.h
//  larchiver
//
//  Created by Lasse Lauwerys on 30/03/24.
//  Copyright (c) 2024 Lasse Lauwerys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuickLook/QuickLook.h>
#import <Quartz/Quartz.h>
#import "LDFile.h"
#import "LDFileTableView.h"
#import "LDFileTableViewDelegate.h"

@class LDFileTableView;

@interface LDFileTableViewController : NSObject <NSTableViewDataSource, QLPreviewPanelDataSource>
{
@private NSURL *outputDirectory;
}


@property LDFile *baseFile;

@property NSMutableArray *layerFiles;
@property NSMutableArray *outputFiles;
@property NSURL* outputDirectory;

@property (nonatomic, readonly) BOOL hasSelectedItems;
@property (nonatomic, readonly) NSIndexSet *selectedItemIndexes;

@property IBOutlet LDFileTableView *tableView;

- (void)setBaseFileWithURL:(NSURL*)url;
- (void)addLayerFile:(LDFile *)file;
- (void)addLayerFile:(LDFile *)file  withOutputFile:(LDFile*)outputFile;
- (void)addLayerFileWithURL:(NSURL*)url;
- (void)addLayerFileWithURL:(NSURL*)inputFileURL andOutputFileURL:(NSURL*)outputFileURL;
- (void)setOutputFile:(LDFile*)file atIndex:(NSUInteger)index;
- (void)setOutputFileWithURL:(NSURL*)url at:(NSUInteger)index;
- (void)removeSelectedItems;
- (void)moveSelectedItems:(BOOL)downwards;
- (void)updateSelections;
- (void)showQuickLook;
- (void)deleteItemAtIndex:(NSUInteger)index;
- (void)setOutputDirectory:(NSURL*)directory;
- (void)setOutputDirectory:(NSURL*)directory atIndexes:(NSIndexSet*)indexes;
- (void)setOutputDirectoryForSelectedItems:(NSURL*)directory;

- (IBAction)deleteSelectedItems:(id)sender;
- (IBAction)moveSelectedItemsUp:(id)sender;
- (IBAction)moveSelectedItemsDown:(id)sender;

@end