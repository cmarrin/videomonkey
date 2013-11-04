//
//  JSONDocument.m
//  VideoMonkey
//
//  Created by Philippe Casgrain on 2013-11-03.
//
//

#import "JSONDocument.h"

@implementation JSONDocument

+ (id)JSONObjectWithData:(NSData *)data options:(JSONReadingOptions)readingOptions error:(NSError **)error
{
    return [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingOptions)readingOptions error:error];
}

@end
