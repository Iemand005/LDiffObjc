//
//  LDiff.h
//  larchiver
//
//  Created by Lasse Lauwerys on 30/03/24.
//  Copyright (c) 2024 Lasse Lauwerys. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <sys/stat.h>

#import "LDFile.h"
#import "LDDiffToolBase.h"

@interface LDDiffTool : LDDiffToolBase
{
    Byte *baseBuffer;
    Byte *layerBuffer;
    
    bool *statuses;
    
    UInt64 baseOffset;
    UInt64 differenceOffset;
    UInt64 differenceLength;
    UInt64 previousDifferenceOffset;
    
    int outputTempBufferCapacity;
    char *outputTempBuffer;
    NSInteger outputTempBufferSize;
}

@property (nonatomic) LDFile *baseFile;
@property (nonatomic) LDFile *headerFile;

- (id)initWithBaseFile:(LDFile *)baseFile andHeaderFile:(LDFile *)headerFile;
- (id)initWithBaseFileName:(NSString *)baseFile andHeaderFileName:(NSString *)headerFile relativeTo:(NSString *)directory;

- (void)setLayerFiles:(NSArray *)newLayerFiles withOutputFiles:(NSArray *)newOutputFiles;
- (void)addLayerWithInputPath:(NSString *)layerFilePath outputPath:(NSString *)outputFilePath;
- (void)addLayerWithInputName:(NSString *)layerPath outputName:(NSString *)outputPath relativeTo:(NSString *)directory;

- (void)compress;

+ (LDDiffTool *)diffTool;
+ (LDDiffTool *)diffToolWithBaseFile:(LDFile *)baseFile andHeaderFile:(LDFile *)headerFile;
+ (LDDiffTool *)diffToolWithBaseFileName:(NSString *)baseFile andHeaderFileName:(NSString *)headerFile relativeTo:(NSString *)directory;

@end
