#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);
void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview);

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
//    @autoreleasepool
//    SKTDrawDocument
    CGSize size;
    size.height = 100;
    size.width = 100;
//    CGContextRef cgContext = QLPreviewRequestCreateContext(preview, size, false, NULL);
//    QLPreviewRequestSetDataRepresentation(
    const char *data = "Hello";
//    CFAllocatorRef allocator;
    CFDataRef htmlData = CFDataCreate(NULL, (UInt32)data, 5);
//    htmlData.
    CFDictionaryRef properties = NULL;
    QLPreviewRequestSetDataRepresentation(preview, (CFDataRef) htmlData,kUTTypeHTML, (CFDictionaryRef)properties);
//    NSURL *url;
    // To complete your generator please implement the function GeneratePreviewForURL in GeneratePreviewForURL.c
    return noErr;
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview)
{
    // Implement only if supported
}
