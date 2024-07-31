//
//  LDDocument.h
//  Diffchiver
//
//  Created by Lasse Lauwerys on 10/04/24.
//  Copyright (c) 2024 Lasse Lauwerys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import <Security/Security.h>
//#import <secu>

#import "LDDiffTool.h"
#import "LDUndiffTool.h"
#import "LDFileTableView.h"
#import "LDDiskTableController.h"

@interface LDDocument : NSDocument
{
    void (^progressAction)(void);
    LDDiffTool *diffTool;
    LDUndiffTool *undiffTool;
    NSTimer *timer;
    BOOL compressing;
    BOOL active;
    long startTime;
    UInt8 indexingMethod;
}

@property (assign) IBOutlet NSWindow *documentWindow;
@property (assign) IBOutlet NSWindow *statusWindow;
@property (assign) IBOutlet NSPanel *confirmationPanel;
@property (assign) IBOutlet NSPanel *compressionWarningPanel;

@property IBOutlet NSMenu *itemMenu;

@property IBOutlet NSMenu *indexingMethodMenu;
@property IBOutlet NSMenuItem *calculateChecksumMenuItem;

@property IBOutlet NSButton *addLayerButton;
@property IBOutlet NSButton *editLayerButton;

@property IBOutlet LDFileTableViewController *fileTableController;
@property IBOutlet LDFileTableViewDelegate *fileTableDelegate;
@property IBOutlet LDFileTableView *fileTable;

@property IBOutlet NSPanel *errorPanel;
@property IBOutlet NSTextView *errorDescriptionTextView;
@property IBOutlet NSTextView *errorRecoveryOptionsTextView;
@property IBOutlet NSButtonCell *errorTryAgainButtonCell;

@property IBOutlet NSButton *toggleCompressionButton;
@property IBOutlet NSTextField *progressBytesLabel;
@property IBOutlet NSTextField *progressSpeedLabel;
@property IBOutlet NSTextField *progressPercentageLabel;
@property IBOutlet NSProgressIndicator *progressIndicator;

@property IBOutlet NSPanel *diskPickerPanel;
@property IBOutlet NSTableView *diskTable;
@property IBOutlet LDDiskTableController *diskTableController;

@property UInt8 indexingMethod;
@property (nonatomic) BOOL calculateChecksum;

- (IBAction)closeSheet:(id)sender;
- (IBAction)openLayerFiles:(id)sender;
- (IBAction)removeSelectedFiles:(id)sender;
- (IBAction)setOutputFiles:(id)sender;
- (IBAction)requestOutputDirectory:(id)sender;
- (IBAction)changeIndexingMethod:(id)sender;
- (IBAction)changeCalculateChecksum:(id)sender;
- (IBAction)extractFileAs:(id)sender;
- (IBAction)openDisk:(id)sender;
- (IBAction)chooseSelectedDisk:(id)sender;

- (IBAction)compress:(id)sender;
- (IBAction)extract:(id)sender;

- (IBAction)modifyTable:(NSSegmentedControl*)sender;

- (IBAction)cancelCompression:(id)sender;

@end
