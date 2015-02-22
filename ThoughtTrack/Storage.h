//
//  Storage.h
//  testevernote
//
//  Created by Ethan Neff on 1/11/15.
//  Copyright (c) 2015 ethanneff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Evernote.h"

@interface Storage : NSObject

typedef NS_ENUM(int16_t, SortType) {  // make strings into constants (global variables)
    SortTypeAZ = 0,
    SortTypeZA = 1,
    SortType19 = 2,
    SortType91 = 3
};

// singleton object
+ (Storage *)sharedInstance;

// local data
- (void) create;
- (void) delete;
- (void) pushData:(id)object forKey:(NSString *)key;
- (NSMutableDictionary *) pullData;
- (NSMutableArray *) pullQueue;

- (NSString *) getUsername;

- (NSArray *) getStackNamesAll;

- (NSArray *) getNotebooksAll;
- (NSArray *) getNotebookNamesAll;
- (NSDictionary *) getNotebookWithGuid:(NSString *)guid;
- (NSDictionary *) getNotebookWithName:(NSString *)name;
- (NSString *) getNotebookNameWithGuid:(NSString *)guid;
- (NSString *) getNotebookGuidWithName:(NSString *)name;

- (NSArray *) getTagsAll;
- (NSArray *) getTagNamesAll;
- (NSArray *) getTagNamesFromTagParentName:(NSString *)tagParentName;
- (NSDictionary *) getTagWithGuid:(NSString *)guid;
- (NSDictionary *) getTagWithName:(NSString *)name;
- (NSString *) getTagGuidWithName:(NSString *)name;
- (NSString *) getTagNameWithGuid:(NSString *)guid;

- (NSArray *) getNotesWithNoteGuids:(NSArray *)noteGuids notebookGuids:(NSArray *)notebookGuids tagGuids:(NSArray *)tagGuids sortType:(SortType)sortType;

@end
