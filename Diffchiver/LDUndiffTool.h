//
//  LUndiff.h
//  larchiver
//
//  Created by Lasse Lauwerys on 10/04/24.
//  Copyright (c) 2024 Lasse Lauwerys. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "LDFile.h"
#import "LDDiffToolBase.h"
#import "LDDataStreamReader.h"
#import "LDFileStreamReader.h"

@interface LDUndiffTool : LDDiffToolBase

@property (nonatomic) NSMutableArray *layerFiles;
@property (nonatomic) NSMutableArray *outputFiles;
@property (nonatomic, strong) LDFile *baseFile;
@property (nonatomic, strong) LDFile *headerFile;

- (UInt64)currentOffset;

- (BOOL)readHeaderFileWithURL:(NSURL *)url error:(NSError **)error;

- (void)extractLayersAtIndexes:(NSIndexSet *)indexes;
- (void)extractAll;

+ (LDUndiffTool *)undiffTool;

@end
