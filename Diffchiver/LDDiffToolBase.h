//
//  LDDiffToolBase.h
//  Diffchiver
//
//  Created by Lasse Lauwerys on 19/04/24.
//  Copyright (c) 2024 Lasse Lauwerys. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "LDFile.h"

enum {
    LDIndexingMethodTransitionOffsets = 1,
    LDIndexingMethodOffsetsAndLengths = 2,
    LDIndexingMethodPositionalOffsets = 3
};
typedef UInt8 LDIndexingMethod;

typedef struct _LDDifference {
    UInt64 offset;
    UInt64 length;
} LDDifference;

@interface LDDiffToolBase : NSObject
{
    UInt64 offset;
    UInt64 layer;
    UInt64 layerCount;
    UInt64 bufferSize;
    UInt64 *layerFileSizes;
    NSMutableArray *layerCRCs;
    NSMutableArray *layerFiles;
    NSMutableArray *outputFiles;
    NSMutableArray *layerMetaBuffers;
    BOOL calculateChecksum;
}

@property NSStringEncoding stringEncoding;
@property LDIndexingMethod indexingMethod;

@property (nonatomic) BOOL calculateChecksum;
@property (nonatomic, readonly) UInt64 currentOffset;
@property (nonatomic, readonly) UInt64 maxOffset;
@property (nonatomic, readonly) UInt8 offsetDataSize;

- (void)addLayerFile:(LDFile *)layerFile withOutputFile:(LDFile *)outputFile;

@end
