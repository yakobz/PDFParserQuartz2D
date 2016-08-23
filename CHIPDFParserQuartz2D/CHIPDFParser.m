//
//  CHIPDFParser.m
//  CHIPDFParserQuartz2D
//
//  Created by Yakov on 8/5/16.
//  Copyright © 2016 CHISW. All rights reserved.
//

#import "CHIPDFParser.h"

static NSMutableArray *strings;
static NSMutableArray *dictionaryKeys;
static NSMutableArray *fontKeys;

static NSString *currentString;

@implementation CHIPDFParser

+ (void)parcePDFWithURL:(NSURL *)pdfFileUrl {
    CGPDFDocumentRef pdfDocument = [self openDocumentWithURL:pdfFileUrl];
    strings = [NSMutableArray array];
    dictionaryKeys = [NSMutableArray array];
    
    if (pdfDocument) {
        CGPDFOperatorTableRef callbacksTable = [self setupOperatorTable];
        NSInteger numberOfPages = CGPDFDocumentGetNumberOfPages(pdfDocument);
        
        for (int i = 0; i < numberOfPages; i++) {
            CGPDFPageRef pdfPage = CGPDFDocumentGetPage(pdfDocument, i + 1);
            [self getFontsFromPdfPage:pdfPage];
            
            CGPDFContentStreamRef pdfContentStream = CGPDFContentStreamCreateWithPage(pdfPage);
            CGPDFScannerRef pdfScanner = CGPDFScannerCreate(pdfContentStream, callbacksTable, NULL);
            
            if(CGPDFScannerScan(pdfScanner) == false) {
                NSLog(@"can't scane pdf document with url: %@", pdfFileUrl);
            }
            
            CGPDFPageRelease(pdfPage);
            CGPDFScannerRelease(pdfScanner);
            CGPDFContentStreamRelease(pdfContentStream);
        }
        
        CGPDFOperatorTableRelease(callbacksTable);
    }
}

+ (CGPDFOperatorTableRef)setupOperatorTable {
    CGPDFOperatorTableRef callbacksTable = CGPDFOperatorTableCreate();
    CGPDFOperatorTableSetCallback(callbacksTable, "TJ", &op_TJ);
    CGPDFOperatorTableSetCallback(callbacksTable, "re", &op_re);
    CGPDFOperatorTableSetCallback(callbacksTable, "Tf", &op_Tf);
    CGPDFOperatorTableSetCallback(callbacksTable, "Do", &op_Do);
    return callbacksTable;
}

+ (CGPDFDocumentRef)openDocumentWithURL:(NSURL *)url {
    CFStringRef path = CFStringCreateWithCString(NULL, [url.path cStringUsingEncoding:NSUTF8StringEncoding], kCFStringEncodingUTF8);
    CFURLRef urlRef = CFURLCreateWithFileSystemPath(NULL, path, kCFURLPOSIXPathStyle, 0);
    CFRelease(path);
    CGPDFDocumentRef document = CGPDFDocumentCreateWithURL(urlRef);
    CFRelease(urlRef);
    return document;
}

#pragma mark - Working With Fonts

+ (void)getFontsFromPdfPage:(CGPDFPageRef)pdfPage {
    CGPDFDictionaryRef pageDictionary = CGPDFPageGetDictionary(pdfPage);
    
    CGPDFDictionaryRef resourcesDictionary;
    CGPDFDictionaryGetDictionary(pageDictionary, "Resources", &resourcesDictionary);
    
    CGPDFDictionaryRef fontDictionary;
    CGPDFDictionaryGetDictionary(resourcesDictionary, "Font", &fontDictionary);
    
    CGPDFDictionaryApplyFunction(fontDictionary, saveKeysFromPdfDictionary, NULL);
    
    [self showFontsFromDictionary:fontDictionary];
}

+ (void)showFontsFromDictionary:(CGPDFDictionaryRef)fontDictionary {
    for (unsigned long i = 0; i < CGPDFDictionaryGetCount(fontDictionary); i++) {
        CGPDFDictionaryRef font;
        CGPDFDictionaryGetDictionary(fontDictionary, [dictionaryKeys[i] UTF8String], &font);
        fontKeys = [NSMutableArray array];
        CGPDFDictionaryApplyFunction(font, saveKeysFromPdfDictionaryForFont, NULL);

        for (NSString *key in fontKeys) {
            NSLog(@"showFontsFromDictionary: %@", key);
            CGPDFObjectRef object;
            CGPDFDictionaryGetObject(font, [key UTF8String], &object);
            parseObject(object);
        }
    }
}

#pragma mark - Callbacks

static void op_re(CGPDFScannerRef scanner, void *info) {
    CGPDFInteger integer;
    
    while (true) {
        if (CGPDFScannerPopInteger(scanner, &integer)) {
            NSLog(@"op_re: %ld", integer);
        } else {
            break;
        }
    }
}

static void op_Tf(CGPDFScannerRef scanner, void *info) {
    CGPDFObjectRef object;
    
    while (true) {
        if (CGPDFScannerPopObject(scanner, &object)) {
            parseObject(object);
        } else {
            break;
        }
    }
}

static void op_TJ(CGPDFScannerRef scanner, void *info) {
    currentString = @"";
    CGPDFObjectRef object;
    
    while (true) {
        if (CGPDFScannerPopObject(scanner, &object)) {
            parseObject(object);
        } else {
            break;
        }
    }
    
    [strings addObject:currentString];
    NSLog(@"op_TJ: %@", strings);
}

static void op_Do(CGPDFScannerRef scanner, void *info) {
    CGPDFObjectRef object;
    
    while (true) {
        if (CGPDFScannerPopObject(scanner, &object)) {
            parseObject(object);
        } else {
            break;
        }
    }
}

#pragma mark - Parse Types

static void parseObject(CGPDFObjectRef object) {
    switch (CGPDFObjectGetType(object)) {
        case kCGPDFObjectTypeNull:          //1
            
            break;
        case kCGPDFObjectTypeBoolean:       //2
            parseBoolean(object);
            break;
        case kCGPDFObjectTypeInteger:       //3
            parseInteger(object);
            break;
        case kCGPDFObjectTypeReal:          //4
            parseReal(object);
            break;
        case kCGPDFObjectTypeName:          //5
            parseName(object);
            break;
        case kCGPDFObjectTypeString:        //6
            parseString(object);
            break;
        case kCGPDFObjectTypeArray:         //7
            parseArray(object);
            break;
        case kCGPDFObjectTypeDictionary:    //8
            parseDictionary(object);
            break;
        case kCGPDFObjectTypeStream:        //9
            NSLog(@"get stream");
            break;
        default:
            break;
    }
}

static void parseBoolean(CGPDFObjectRef object) {
    CGPDFBoolean boolValue;
    if (CGPDFObjectGetValue(object, CGPDFObjectGetType(object), &boolValue)) {
        NSLog(@"parseBoolean: %u", boolValue);
    }
}

static void parseInteger(CGPDFObjectRef object) {
    void *value;
    if (CGPDFObjectGetValue(object, CGPDFObjectGetType(object), &value)) {
        CGPDFInteger integer = (CGPDFInteger)value;
        NSLog(@"parseInteger: %ld", integer);
    }
}

static void parseReal(CGPDFObjectRef object) {
    CGPDFReal real;
    if (CGPDFObjectGetValue(object, CGPDFObjectGetType(object), &real)) {
        NSLog(@"parseReal: %f", real);
    }
}

static void parseName(CGPDFObjectRef object) {
    void *value;
    if (CGPDFObjectGetValue(object, CGPDFObjectGetType(object), &value)) {
        const char *name = (char *)value;
        NSString *resultString = [NSString stringWithUTF8String:name];
        NSLog(@"parseName: %@", resultString);
    }
}

static void parseString(CGPDFObjectRef object) {
    void *value;
    if (CGPDFObjectGetValue(object, CGPDFObjectGetType(object), &value)) {
        CGPDFStringRef string = (CGPDFStringRef)value;
        NSString *resultString = (NSString *)CFBridgingRelease(CGPDFStringCopyTextString(string));
        currentString = [currentString stringByAppendingString:resultString];
    }
}

static void parseArray(CGPDFObjectRef object) {
    void *value;
    if (CGPDFObjectGetValue(object, CGPDFObjectGetType(object), &value)) {
        CGPDFArrayRef array = (CGPDFArrayRef)(value);
        
        for (int i = 0; i < CGPDFArrayGetCount(array); i++) {
            CGPDFObjectRef parsedObject;
            
            if (CGPDFArrayGetObject(array, i, &parsedObject)) {
                parseObject(parsedObject);
            }
        }
    }
}

static void parseDictionary(CGPDFObjectRef object) {
    void *value;
//    if (CGPDFObjectGetValue(object, CGPDFObjectGetType(object), value)) {
//        CGPDFDictionaryRef dictionary = (CGPDFDictionaryRef)value;
//        CGPDFDictionaryApplyFunction(dictionary, showKeysFromPdfDictionary, NULL);
//    }
}

#pragma mark - Helper Methods

static void saveKeysFromPdfDictionary(const char *key, CGPDFObjectRef object, void *info) {
    [dictionaryKeys addObject:[NSString stringWithUTF8String:key]];
}

static void saveKeysFromPdfDictionaryForFont(const char *key, CGPDFObjectRef object, void *info) {
    [fontKeys addObject:[NSString stringWithUTF8String:key]];
}

static void showKeysFromPdfDictionary(const char *key, CGPDFObjectRef object, void *info) {
    NSLog(@"showKeysFromPdfDictionary: %@", [NSString stringWithUTF8String:key]);
}

@end
