//
//  CHIPDFParser.h
//  CHIPDFParserQuartz2D
//
//  Created by Yakov on 8/5/16.
//  Copyright © 2016 CHISW. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CHIPDFParser : NSObject

+ (void)parcePDFWithURL:(NSURL *)pdfFileUrl;

@end
