//
//  Evernote.h
//  testevernote
//
//  Created by Ethan Neff on 1/2/15.
//  Copyright (c) 2015 ethanneff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "Util.h"
#import <ENSDK/Advanced/ENSDKAdvanced.h>

@interface Evernote : NSObject

// user
+ (void) login:(UIViewController *)viewController completion:(void (^)(NSError *error))completion;
+ (void) logout;
+ (bool) isAuthenticated;
+ (bool) isConnected;

// all
+ (void) getAll:(void (^)(NSError *error))completion;
+ (void) getTags:(void (^)(NSError *error))completion;
+ (void) getSearches:(void (^)(NSError *error))completion;
+ (void) getNotebooks:(void (^)(NSError *error))completion;
+ (void) getNotes:(void (^)(NSError *error))completion;

// individual
+ (void) getNoteContents:(NSString *)noteGuid completion:(void (^)(NSString *noteContent))completion;
+ (void) getNoteGuidsWithSearch:(NSString *)search completion:(void (^)(NSArray *noteGuids))completion;

// tags
+ (void) createTag:(NSString *)tagName parentGuid:(NSString *)parentGuid completion:(void (^)(NSError *error))completion;
+ (void) updateTag:(NSString *)tagName tagGuid:(NSString *)tagGuid tagParentGuid:(NSString *)tagParentGuid completion:(void (^)(NSError *error))completion;

// notebooks (able to create new stacks)
+ (void) createNotebook:(NSString *)name stack:(NSString *)stack completion:(void (^)(NSError *error))completion;

// notes
+ (void) createNote:(NSString *)title content:(NSString *)content notebookGuid:(NSString *)notebookGuid tagGuids:(NSArray *)tagGuids completion:(void (^)(NSError *error))completion;
+ (void) updateNote:(NSString *)noteGuid title:(NSString *)title content:(NSString *)content notebookGuid:(NSString *)notebookGuid tagGuids:(NSArray *)tagGuids completion:(void (^)(NSError *error))completion;
+ (void) deleteNote:(NSString *)noteGuid completion:(void (^)(NSError *error))completion;

// indexes
+ (void) createTagIndexes:(void (^)(NSError *error))completion;
+ (void) createNotebookIndexes:(void (^)(NSError *error))completion;
+ (void) createNoteIndexes:(void (^)(NSError *error))completion;


@end
