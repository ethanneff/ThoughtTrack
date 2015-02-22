//
//  Storage.m
//  testevernote
//
//  Created by Ethan Neff on 1/11/15.
//  Copyright (c) 2015 ethanneff. All rights reserved.
//

#import "Storage.h"
#import "Util.h"

@implementation Storage

// static = this file only
static Storage *sharedInstance = nil;

// singleton
+ (Storage *) sharedInstance {
    if (sharedInstance == nil) {
        // Thread safe allocation and initialization -> singletone object
        static dispatch_once_t pred;
        dispatch_once(&pred, ^{
            sharedInstance = [[Storage alloc] init];
        });
    }
    
    return sharedInstance;
}

#pragma mark - Local Storage
- (void) create {
    [[NSUserDefaults standardUserDefaults] setObject:[[NSMutableDictionary alloc] init] forKey:@"evernoteData"];
    [[NSUserDefaults standardUserDefaults] setObject:[[NSMutableArray alloc] init] forKey:@"evernoteQueue"];
}

- (void) delete {
    [self create];
}

- (void) pushData:(id)object forKey:(NSString *)key {
    // pull, set, push
    NSMutableDictionary *data = [self pullData];
    [data setObject:object forKey:key];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:@"evernoteData"];
}


- (NSMutableDictionary *) pullData {
    return [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"evernoteData"]];
}

- (NSMutableArray *) pullQueue {
    return [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"evernoteData"]];
}


#pragma mark - Local Methods

#pragma mark - user
- (NSString *) getUsername {
    return [[self pullData] objectForKey:@"username"];
}

#pragma mark - stacks
- (NSArray *) getStackNamesAll {
    NSMutableArray *stackNames = [NSMutableArray array];
    for (NSArray *stackNotebooks in [[[self pullData] objectForKey:@"indexes"] objectForKey:@"groupNotebooksByStackName"]) {
        [stackNames addObject:stackNotebooks[0]];
    }
    return stackNames;
}

#pragma mark - notebooks
- (NSArray *) getNotebooksAll {
    // unordered
    return [[self pullData] objectForKey:@"notebooks"];
}

- (NSArray *) getNotebookNamesAll {
    NSMutableArray *notebooks = [NSMutableArray array];
    for (NSArray *notebookLocation in [[[self pullData] objectForKey:@"indexes"] objectForKey:@"sortNotebooksByName"]) {
        [notebooks addObject:notebookLocation[0]];
    }
    
    return notebooks;
}

- (NSDictionary *) getNotebookWithGuid:(NSString *)guid {
    if (guid == nil) return nil;
    NSArray *notebookLocations = [self binarySearchWithArray:[[[self pullData] objectForKey:@"indexes"] objectForKey:@"sortNotebooksByGuid"] andItem:guid];
    if ([notebookLocations count] > 1) {
        return [[[self pullData] objectForKey:@"notebooks"] objectAtIndex:[notebookLocations[1] integerValue]];
    }
    return nil;
}

- (NSDictionary *) getNotebookWithName:(NSString *)name {
    if (name == nil) return nil;
    NSArray *notebookLocations = [self binarySearchWithArray:[[[self pullData] objectForKey:@"indexes"] objectForKey:@"sortNotebooksByName"] andItem:name];
    if ([notebookLocations count] > 1) {
        return [[[self pullData] objectForKey:@"notebooks"] objectAtIndex:[notebookLocations[1] integerValue]];
    }
    return nil;
}

- (NSString *) getNotebookNameWithGuid:(NSString *)guid {
    if (guid == nil) return nil;
    NSArray *notebookLocations = [self binarySearchWithArray:[[[self pullData] objectForKey:@"indexes"] objectForKey:@"sortNotebooksByGuid"] andItem:guid];
    if ([notebookLocations count] > 1) {
        return [[[self pullData] objectForKey:@"notebooks"] objectAtIndex:[notebookLocations[1] integerValue]][@"notebookName"];
    }
    return nil;
}

- (NSString *) getNotebookGuidWithName:(NSString *)name {
    if (name == nil) return nil;
    NSArray *notebookLocations = [self binarySearchWithArray:[[[self pullData] objectForKey:@"indexes"] objectForKey:@"sortNotebooksByName"] andItem:name];
    if ([notebookLocations count] > 1) {
        return [[[self pullData] objectForKey:@"notebooks"] objectAtIndex:[notebookLocations[1] integerValue]][@"notebookGuid"];
    }
    return nil;
}

#pragma mark - tags
- (NSArray *) getTagsAll {
    return [[self pullData] objectForKey:@"tags"];
    return nil;
}

- (NSArray *) getTagNamesAll {
    NSMutableArray *tagNames = [NSMutableArray array];
    for (NSArray *tagLocations in [[[self pullData] objectForKey:@"indexes"] objectForKey:@"sortTagsByName"]) {
        [tagNames addObject:tagLocations[0]];
    }
    
    return tagNames;
}

- (NSArray *) getTagNamesFromTagParentName:(NSString *)tagParentName {
    NSString *parentTagGuid = [self getTagGuidWithName:tagParentName];
    NSArray *subTagLocations = [self binarySearchWithArray:[[[self pullData] objectForKey:@"indexes"] objectForKey:@"groupTagsByTagParentGuid"] andItem:parentTagGuid];
    
    // TODO: only pull tags with greater than 1
    
    //    NSArray *tags = [[self pullData] objectForKey:@"tags"];
    //    for (NSInteger i = 1; i < subTagLocations.count; i++) {
    //        NSString *tagGuid = [tags objectAtIndex:[subTagLocations[i] integerValue]][@"tagGuid"];
    //        // compare with  @"groupNotesByTagGuid" index to see if array count is greater than 1
    //    }
    //
    // sort
    NSArray *tagLocations = [[[self pullData] objectForKey:@"indexes"] objectForKey:@"sortTagsByName"];
    NSMutableArray *sortTagNames = [NSMutableArray array];
    if (tagLocations.count > 0) {
        for (NSArray *tagLocation in tagLocations) {
            if ([subTagLocations indexOfObject:tagLocation[1]] != NSNotFound) {
                [sortTagNames addObject:tagLocation[0]];
            }
        }
    }
    
    return sortTagNames;
}

- (NSDictionary *) getTagWithGuid:(NSString *)guid {
    if (guid == nil) return nil;
    NSArray *tagLocations = [self binarySearchWithArray:[[[self pullData] objectForKey:@"indexes"] objectForKey:@"sortTagsByGuid"] andItem:guid];
    if ([tagLocations count] > 1) {
        return [[[self pullData] objectForKey:@"tags"] objectAtIndex:[tagLocations[1] integerValue]];
    }
    return nil;
}

- (NSDictionary *) getTagWithName:(NSString *)name {
    if (name == nil) return nil;
    NSArray *tagLocations = [self binarySearchWithArray:[[[self pullData] objectForKey:@"indexes"] objectForKey:@"sortTagsByName"] andItem:name];
    if ([tagLocations count] > 1) {
        return [[[self pullData] objectForKey:@"tags"] objectAtIndex:[tagLocations[1] integerValue]];
    }
    return nil;
}

- (NSString *) getTagGuidWithName:(NSString *)name {
    if (name == nil) return nil;
    NSArray *tagLocations = [self binarySearchWithArray:[[[self pullData] objectForKey:@"indexes"] objectForKey:@"sortTagsByName"] andItem:name];
    if ([tagLocations count] > 1) {
        return [[[self pullData] objectForKey:@"tags"] objectAtIndex:[tagLocations[1] integerValue]][@"tagGuid"];
    }
    return nil;
}

- (NSString *) getTagNameWithGuid:(NSString *)guid {
    if (guid == nil) return nil;
    NSArray *tagLocations = [self binarySearchWithArray:[[[self pullData] objectForKey:@"indexes"] objectForKey:@"sortTagsByGuid"] andItem:guid];
    if ([tagLocations count] > 1) {
        return [[[self pullData] objectForKey:@"tags"] objectAtIndex:[tagLocations[1] integerValue]][@"tagName"];
    }
    return nil;
}

#pragma mark - notes
- (NSArray *) getNotesWithNoteGuids:(NSArray *)noteGuids notebookGuids:(NSArray *)notebookGuids tagGuids:(NSArray *)tagGuids sortType:(SortType)sortType {
    NSLog(@"storage getnotes");
    NSMutableArray *noteLocations = [NSMutableArray array];
    NSMutableArray *sortedNoteLocations = [NSMutableArray array];
    
    // note guids
    if ([noteGuids count] > 0) {
        for (NSString *noteGuid in noteGuids) {
            NSArray *location = [self binarySearchWithArray:[[[self pullData] objectForKey:@"indexes"] objectForKey:@"sortNotesByGuid"] andItem:noteGuid];
            if ([location count] > 1) {
                [noteLocations addObject:location[1]];
            }
        }
    }
    
    // notebook guids
    if ([notebookGuids count] > 0) {
        if ([noteGuids count] > 0) {
            NSMutableArray *newNoteLocations = [NSMutableArray arrayWithArray:noteLocations];
            for (NSString *noteLocation in noteLocations) {
                // if the notebook guid from the previous found noteguid is not found in the notebookGuid parameter array, remove that noteguid
                if ([notebookGuids indexOfObject:[[[self pullData] objectForKey:@"notes"] objectAtIndex:[noteLocation intValue]][@"noteNotebookGuid"]] == NSNotFound) {
                    [newNoteLocations removeObject:noteLocation];
                }
            }
            noteLocations = newNoteLocations;
        } else {
            // add note locations from all notebookguids
            for (NSString *notebookGuid in notebookGuids) {
                NSArray *location = [self binarySearchWithArray:[[[self pullData] objectForKey:@"indexes"] objectForKey:@"groupNotesByNotebookGuid"] andItem:notebookGuid];
                if ([location count] > 1) {
                    for (NSInteger i = 1; i < [location count]; i++) {
                        [noteLocations addObject:location[i]];
                    }
                }
            }
        }
    }
    
    // tag guids
    if ([tagGuids count] > 0) {
        if ([noteGuids count] > 0 || [notebookGuids count] > 0) {
            NSMutableArray *newNoteLocations = [NSMutableArray arrayWithArray:noteLocations];
            for (NSString *noteLocation in noteLocations) {
                // if tagGuids paramenter not found within the noteTags from the previous found note locations, remove that location
                if (![Util isArray:tagGuids withinArray:[[[self pullData] objectForKey:@"notes"] objectAtIndex:[noteLocation intValue]][@"noteTagGuids"]]) {
                    [newNoteLocations removeObject:noteLocation];
                }
            }
            noteLocations = newNoteLocations;
        } else {
            // add note locations from all tagguids
            NSLog(@"not here");
            for (NSString *tagGuid in tagGuids) {
                NSArray *location = [self binarySearchWithArray:[[[self pullData] objectForKey:@"indexes"] objectForKey:@"groupNotesByTagGuid"] andItem:tagGuid];
                if ([location count] > 1) {
                    for (NSInteger i = 1; i < [location count]; i++) {
                        [noteLocations addObject:location[i]];
                    }
                }
            }
        }
    }
    
    // check for initial notes load
    BOOL all = false;
    if ([noteGuids count] == 0 && [notebookGuids count] == 0 && [tagGuids count] == 0) all = true;
    
    // sort
    if (sortType == SortTypeAZ) {
        NSArray *sortedLocations = [[[self pullData] objectForKey:@"indexes"] objectForKey:@"sortNotesByTitle"];
        for (NSInteger i = 0; i < sortedLocations.count; i++) {
            if ([noteLocations indexOfObject:sortedLocations[i][1]] != NSNotFound || all) {
                [sortedNoteLocations addObject:sortedLocations[i][1]];
            }
        }
    } else if (sortType == SortTypeZA) {
        NSArray *sortedLocations = [[[self pullData] objectForKey:@"indexes"] objectForKey:@"sortNotesByTitle"];
        for (NSInteger i = sortedLocations.count-1; i >= 0; i--) {
            if ([noteLocations indexOfObject:sortedLocations[i][1]] != NSNotFound || all) {
                [sortedNoteLocations addObject:sortedLocations[i][1]];
            }
        }
    } else if (sortType == SortType19) {
        NSArray *sortedLocations = [[[self pullData] objectForKey:@"indexes"] objectForKey:@"sortNotesByUpdated"];
        for (NSInteger i = sortedLocations.count-1; i >= 0; i--) {
            if ([noteLocations indexOfObject:sortedLocations[i][1]] != NSNotFound || all) {
                [sortedNoteLocations addObject:sortedLocations[i][1]];
            }
        }
    } else if (sortType == SortType91) {
        NSArray *sortedLocations = [[[self pullData] objectForKey:@"indexes"] objectForKey:@"sortNotesByUpdated"];
        for (NSInteger i = 0; i < sortedLocations.count; i++) {
            if ([noteLocations indexOfObject:sortedLocations[i][1]] != NSNotFound || all) {
                [sortedNoteLocations addObject:sortedLocations[i][1]];
            }
        }
    }
    
    // note
    NSMutableArray *notes = [NSMutableArray array];
    for (NSString *location in sortedNoteLocations) {
        [notes addObject:[[[self pullData] objectForKey:@"notes"] objectAtIndex:[location intValue]]];
    }
    
    return notes;
}

#pragma mark - binary search
- (NSArray *) binarySearchWithArray:(NSArray *)array andItem:(NSString *)item {
    unsigned long mid;
    unsigned long min = 0;
    unsigned long max = [array count] - 1;
    
    while (min <= max) {
        mid = (min + max)/ 2;
        NSString *word = [array objectAtIndex:mid][0];
        if ([item caseInsensitiveCompare:word] == NSOrderedSame) {
            return [array objectAtIndex:mid];
        } else if ([item caseInsensitiveCompare:word] == NSOrderedAscending) {
            max = mid - 1;
        } else {
            min = mid + 1;
        }
    }
    return @[];
}

@end
