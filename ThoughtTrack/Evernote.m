//
//  Evernote.m
//  testevernote
//
//  Created by Ethan Neff on 1/2/15.
//  Copyright (c) 2015 ethanneff. All rights reserved.
//

#import "Evernote.h"
#import "Storage.h"

@interface Evernote()

@end

@implementation Evernote

#pragma mark - User
+ (bool) isAuthenticated {
    [ENSession setDisableRefreshingNotebooksCacheOnLaunch:YES];
    return [[ENSession sharedSession] isAuthenticated];
}

+ (bool) isConnected {
    if ([self isAuthenticated]) {
        if (![[Util getNetworkStatus] isEqualToString:@"No Connection"]) {
            return true;
        } else {
            [Util showSimpleAlertWithMessage:@"No network connection"];
        }
    } else {
        [Util showSimpleAlertWithMessage:@"Please login to Evernote first"];
    }
    return false;
}

+ (void) login:(UIViewController *)viewController completion:(void (^)(NSError *error))completion {
    if (![[Util getNetworkStatus] isEqualToString:@"No Connection"]) {
        [self logout];
        [[ENSession sharedSession] authenticateWithViewController:viewController
                                               preferRegistration:NO
                                                       completion:^(NSError *authenticateError) {
                                                           if (!authenticateError) {
                                                               [ENSession setDisableRefreshingNotebooksCacheOnLaunch:YES];
                                                               [[Storage sharedInstance] create];
                                                               [[Storage sharedInstance] pushData:[[ENSession sharedSession] userDisplayName] forKey:@"username"];
                                                               completion(nil);
                                                           } else if (authenticateError.code != ENErrorCodeCancelled) {
                                                               [Util showSimpleAlertWithMessage:@"Could not authenticate user"];
                                                               completion(authenticateError);
                                                           }
                                                       }];
    } else {
        [Util showSimpleAlertWithMessage:@"No network connection"];
        NSError *error = [NSError errorWithDomain:@"No network connection" code:0 userInfo:nil];
        completion(error);
    }
}

+ (void) logout {
    [[ENSession sharedSession] unauthenticate];
    [[Storage sharedInstance] delete];
}

#pragma mark - Get
+ (void) getAll:(void (^)(NSError *error))completion {
    if ([self isConnected]) {
        // reset storage
        [[Storage sharedInstance] delete];
        [[Storage sharedInstance] create];
        [[Storage sharedInstance] pushData:[[ENSession sharedSession] userDisplayName] forKey:@"username"];
        
        // pull all from evernote
        __block NSInteger completed = 0;
        __block NSInteger total = 4;
        [self getTags:^(NSError *error) {
            NSLog(@"got tags %@", error);
            completed++;
            (completed==total) ? completion(error) : nil;
        }];
        [self getSearches:^(NSError *error) {
            NSLog(@"got searches %@", error);
            completed++;
            (completed==total) ? completion(error) : nil;
        }];
        [self getNotebooks:^(NSError *error) {
            NSLog(@"got notebooks %@", error);
            completed++;
            (completed==total) ? completion(error) : nil;
        }];
        [self getNotes:^(NSError *error) {
            NSLog(@"got notes %@", error);
            completed++;
            (completed==total) ? completion(error) : nil;
        }];
    } else {
        NSError *error = [[NSError alloc] initWithDomain:@"error" code:0 userInfo:nil];
        completion(error);
    }
}

+ (void) getTags:(void (^)(NSError *error))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[[ENSession sharedSession] primaryNoteStore] listTagsWithSuccess:^(NSArray *tags) {
            // create array of dictionaries
            NSMutableArray *arrTags = [[NSMutableArray alloc] init];
            for (EDAMTag *tag in tags) {
                NSString *tagParentGuid = (tag.parentGuid == nil) ? @"" : tag.parentGuid;
                
                NSDictionary *dictTag = [NSDictionary dictionaryWithObjects:@[tag.guid, tag.name, tagParentGuid] forKeys:@[@"tagGuid", @"tagName", @"tagParentGuid"]];
                [arrTags addObject:dictTag];
            }
            
            // store the unsorted array
            [[Storage sharedInstance] pushData:arrTags forKey:@"tags"];
            
            // create indexes
            [self createTagIndexes:^(NSError *error) {
                completion(nil);
            }];
        } failure:^(NSError *error) {
            [[Storage sharedInstance] pushData:@[] forKey:@"tags"];
            [Util showSimpleAlertWithMessage:@"failed to get tags" andButton:nil forSeconds:0.4];
            completion(error);
        }];
    });
}

+ (void) getSearches:(void (^)(NSError *error))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // TODO: move all evernote pulls into try catch block (had a crash here)
        [[[ENSession sharedSession] primaryNoteStore] listSearchesWithSuccess:^(NSArray *searches) {
            // create array of dictionaries
            NSMutableArray *arrSearches = [[NSMutableArray alloc] init];
            for (EDAMSavedSearch *search in searches) {
                NSDictionary *dictSearch = [NSDictionary dictionaryWithObjects:@[search.guid, search.name, search.query] forKeys:@[@"searchGuid", @"searchName", @"searchQuery"]];
                [arrSearches addObject:dictSearch];
            }
            // sort array
            arrSearches = [NSMutableArray arrayWithArray:[arrSearches sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"searchName" ascending:YES selector:@selector(caseInsensitiveCompare:)]]]];
            
            // store array
            [[Storage sharedInstance] pushData:arrSearches forKey:@"searches"];
            completion(nil);
        } failure:^(NSError *error) {
            [[Storage sharedInstance] pushData:@[] forKey:@"searches"];
            [Util showSimpleAlertWithMessage:@"failed to get searches" andButton:nil forSeconds:0.4];
            completion(error);
        }];
    });
}

+ (void) getNotebooks:(void (^)(NSError *error))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[[ENSession sharedSession] primaryNoteStore] listNotebooksWithSuccess:^(NSArray *notebooks) {
            // create array of dictionaries
            NSMutableArray *arrNotebooks = [[NSMutableArray alloc] init];
            for (EDAMNotebook *notebook in notebooks) {
                NSString *notebookStackName = (notebook.stack == nil) ? @"" : notebook.stack;
                NSDictionary *dictNotebook = [NSDictionary dictionaryWithObjects:@[notebook.guid, notebook.name, notebookStackName, notebook.defaultNotebook] forKeys:@[@"notebookGuid", @"notebookName", @"notebookStackName", @"notebookDefault"]];
                [arrNotebooks addObject:dictNotebook];
            }
            // store unsorted array
            [[Storage sharedInstance] pushData:arrNotebooks forKey:@"notebooks"];
            
            // create indexes
            [self createNotebookIndexes:^(NSError *error) {
                completion(nil);
            }];
            
        } failure:^(NSError *error) {
            [[Storage sharedInstance] pushData:@[] forKey:@"notebooks"];
            [Util showSimpleAlertWithMessage:@"failed to get notebooks" andButton:nil forSeconds:0.4];
            completion(error);
        }];
    });
}

// all notes
+ (void) getNotes:(void (^)(NSError *error))completion {
    EDAMNoteFilter *filter = [[EDAMNoteFilter alloc] init];
    [filter setOrder:0];                                    // sort
    [filter setAscending:[NSNumber numberWithBool:NO]];     // sort
    [filter setWords:@""];                                  // search keywords
    [filter setNotebookGuid:nil];                           // notebook
    [filter setTagGuids:nil];                               // tags array
    [filter setTimeZone:nil];                               // "yesterday"
    [filter setInactive:[NSNumber numberWithBool:NO]];      // include trash?
    [filter setEmphasized:nil];                             // preferred search
    
    EDAMNotesMetadataResultSpec *results = [[EDAMNotesMetadataResultSpec alloc] init];
    [results setIncludeTitle:[NSNumber numberWithInt:1]];
    [results setIncludeContentLength:[NSNumber numberWithInt:0]];
    [results setIncludeCreated:[NSNumber numberWithInt:1]];
    [results setIncludeUpdated:[NSNumber numberWithInt:1]];
    [results setIncludeDeleted:[NSNumber numberWithInt:0]];
    [results setIncludeUpdateSequenceNum:[NSNumber numberWithInt:0]];
    [results setIncludeNotebookGuid:[NSNumber numberWithInt:1]];
    [results setIncludeTagGuids:[NSNumber numberWithInt:1]];
    [results setIncludeAttributes:[NSNumber numberWithInt:0]];
    [results setIncludeLargestResourceMime:[NSNumber numberWithInt:0]];
    [results setIncludeLargestResourceSize:[NSNumber numberWithInt:0]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // get count (16kb)
        [[[ENSession sharedSession] primaryNoteStore] findNotesMetadataWithFilter:filter offset:0 maxNotes:0 resultSpec:results success:^(EDAMNotesMetadataList *metadata) {
            [[Storage sharedInstance] pushData:@[] forKey:@"notes"];
            // loops through evernote (50 notes at a time)
            for (NSInteger i = 0; i < [metadata.totalNotes integerValue]; i=i+50) {
                [[[ENSession sharedSession] primaryNoteStore] findNotesMetadataWithFilter:filter offset:(int)i maxNotes:50 resultSpec:results success:^(EDAMNotesMetadataList *metadata) {
                    // add notes to storage
                    NSMutableArray *arrNotes = [NSMutableArray arrayWithArray:[[[Storage sharedInstance] pullData] objectForKey:@"notes"]];
                    for (EDAMNoteMetadata *note in metadata.notes) {
                        // handle nulls
                        NSString *noteTitle = (note.title == nil) ? @"" : note.title;
                        NSString *noteNotebookGuid = (note.notebookGuid == nil) ? @"" : note.notebookGuid;
                        NSArray *noteTagGuids = (note.tagGuids == nil) ? @[] : note.tagGuids;
                        
                        // make dict and add to array
                        NSDictionary *dictNote = [NSDictionary dictionaryWithObjects:@[note.guid, noteTitle, note.created, note.updated, noteNotebookGuid, noteTagGuids] forKeys:@[@"noteGuid", @"noteTitle", @"noteCreated", @"noteUpdated", @"noteNotebookGuid", @"noteTagGuids"]];
                        [arrNotes addObject:dictNote];
                    }
                    // store notes
                    [[Storage sharedInstance] pushData:arrNotes forKey:@"notes"];
                    
                    // last chunk pull
                    if (arrNotes.count == [metadata.totalNotes integerValue]) {
                        // create indexes
                        [self createNoteIndexes:^(NSError *error) {
                            // complete
                            completion(nil);
                        }];
                    }
                } failure:^(NSError *error) {
                    [Util showSimpleAlertWithMessage:@"failed to get notes" andButton:nil forSeconds:0.4];
                    completion(error);
                }];
            }
        } failure:^(NSError *error) {
            [Util showSimpleAlertWithMessage:@"failed to get notes" andButton:nil forSeconds:0.4];
            completion(error);
        }];
    });
}

#pragma mark - individual
+ (void) getNoteContents:(NSString *)noteGuid completion:(void (^)(NSString *noteContent))completion {
    if ([self isConnected]) {
        // download contents
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[[ENSession sharedSession] primaryNoteStore] getNoteContentWithGuid:noteGuid success:^(NSString *content) {
                // complete
                completion(content);
            } failure:^(NSError *error) {
                [Util showSimpleAlertWithMessage:@"Failed to get note contents" andButton:nil forSeconds:0.4];
                completion(nil);
            }];
        });
        
    }
}


// search with text
+ (void) getNoteGuidsWithSearch:(NSString *)search completion:(void (^)(NSArray *noteGuids))completion  {
    if ([self isConnected]) {
        search = (search == nil) ? @"" : search;
        
        EDAMNoteFilter *filter = [[EDAMNoteFilter alloc] init];
        [filter setWords:search];
        EDAMNotesMetadataResultSpec *results = [[EDAMNotesMetadataResultSpec alloc] init];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // get count (16kb)
            [[[ENSession sharedSession] primaryNoteStore] findNotesMetadataWithFilter:filter offset:0 maxNotes:0 resultSpec:results success:^(EDAMNotesMetadataList *metadata) {
                if (metadata.totalNotes == [NSNumber numberWithInt:0]) {
                    [Util showSimpleAlertWithMessage:@"No notes found with search" andButton:nil forSeconds:0.4];
                    completion(nil);
                } else {
                    NSMutableArray *searchNoteGuids = [NSMutableArray array];
                    // loops through evernote (50 notes at a time)
                    for (NSInteger i = 0; i < [metadata.totalNotes integerValue]; i=i+50) {
                        [[[ENSession sharedSession] primaryNoteStore] findNotesMetadataWithFilter:filter offset:(int)i maxNotes:50 resultSpec:results success:^(EDAMNotesMetadataList *metadata) {
                            // add notes to temp array
                            for (EDAMNoteMetadata *note in metadata.notes) {
                                [searchNoteGuids addObject:note.guid];
                            }
                            
                            // if last chunk pull
                            if (searchNoteGuids.count == [metadata.totalNotes integerValue]) {
                                // complete
                                completion(searchNoteGuids);
                            }
                        } failure:^(NSError *error) {
                            [Util showSimpleAlertWithMessage:@"Failed to get notes with search" andButton:nil forSeconds:0.4];
                            completion(nil);
                        }];
                    }
                }
            } failure:^(NSError *error) {
                [Util showSimpleAlertWithMessage:@"Failed to get notes with search" andButton:nil forSeconds:0.4];
                completion(nil);
            }];
        });
    }
}

#pragma mark - Tags
// pass nil if no parent guid
+ (void) createTag:(NSString *)tagName parentGuid:(NSString *)parentGuid completion:(void (^)(NSError *error))completion {
    // must have network connection because search is based on tagGuids of the note
    if ([self isConnected]) {
        // clean
        tagName = [tagName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        //remote
        EDAMTag *newTag = [[EDAMTag alloc] init];
        newTag.name = tagName;
        newTag.parentGuid = parentGuid;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[[ENSession sharedSession] primaryNoteStore] createTag:newTag success:^(EDAMTag *tag) {
                // local (pull, add, push)
                NSMutableArray *arrTags = [NSMutableArray arrayWithArray:[[[Storage sharedInstance] pullData] objectForKey:@"tags"]];
                NSDictionary *dictTag = [NSDictionary dictionaryWithObjects:@[tag.guid, tag.name, (tag.parentGuid == nil) ? @"" : tag.parentGuid] forKeys:@[@"tagGuid", @"tagName", @"tagParentGuid"]];
                [arrTags addObject:dictTag];
                [[Storage sharedInstance] pushData:arrTags forKey:@"tags"];
                
                // complete
                [self createTagIndexes:^(NSError *error) {
                    [Util showSimpleAlertWithMessage:@"Successful tag creation" andButton:nil forSeconds:0.4];
                    completion(nil);
                }];
            } failure:^(NSError *error) {
                [Util showSimpleAlertWithMessage:@"Failed to create new tag"];
                completion(error);
            }];
        });
    } else {
        completion([NSError errorWithDomain:@"Could not connect to Evernote" code:0 userInfo:nil]);
    }
}

+ (void) updateTag:(NSString *)tagName tagGuid:(NSString *)tagGuid tagParentGuid:(NSString *)tagParentGuid completion:(void (^)(NSError *error))completion {
    if ([self isConnected]) {
        // clean
        tagName = [tagName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        tagGuid = [tagGuid stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        tagParentGuid = [tagParentGuid stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if ([tagName length] == 0 || [tagGuid length] == 0) {
            [Util showSimpleAlertWithMessage:@"Tag must have a name"];
        } else {
            // remote
            EDAMTag *updateTag = [[EDAMTag alloc] init];
            updateTag.guid = tagGuid;
            updateTag.name = tagName;
            updateTag.parentGuid = tagParentGuid;
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [[[ENSession sharedSession] primaryNoteStore] updateTag:updateTag success:^(int32_t usn) {
                    // local (pull, remove, add, push)
                    NSMutableArray *arrTags = [NSMutableArray arrayWithArray:[[[Storage sharedInstance] pullData] objectForKey:@"tags"]];
                    for (NSInteger i = 0; i < [arrTags count]; i++) {
                        if ([arrTags[i][@"tagGuid"] isEqualToString:tagGuid]) {
                            [arrTags removeObjectAtIndex:i];
                            break;
                        }
                    }
                    NSDictionary *dictTag = [NSDictionary dictionaryWithObjects:@[tagGuid, tagName, (tagParentGuid == nil) ? @"" : tagParentGuid] forKeys:@[@"tagGuid", @"tagName", @"tagParentGuid"]];
                    [arrTags addObject:dictTag];
                    [[Storage sharedInstance] pushData:arrTags forKey:@"tags"];
                    
                    // complete
                    [self createTagIndexes:^(NSError *error) {
                        [Util showSimpleAlertWithMessage:@"Successful tag update" andButton:nil forSeconds:0.4];
                        completion(nil);
                    }];
                } failure:^(NSError *error) {
                    [Util showSimpleAlertWithMessage:@"Failed to update tag"];
                    completion(error);
                }];
            });
        }
    } else {
        completion([NSError errorWithDomain:@"Could not connect to Evernote" code:0 userInfo:nil]);
    }
}

#pragma mark - Notebook
+ (void) createNotebook:(NSString *)name stack:(NSString *)stack completion:(void (^)(NSError *error))completion {
    if ([self isConnected]) {
        // clean
        name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        stack = [stack stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        EDAMNotebook *newNotebook = [[EDAMNotebook alloc] init];
        [newNotebook setName:name];
        [newNotebook setStack:stack];
        
        // remote
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[[ENSession sharedSession] primaryNoteStore] createNotebook:newNotebook success:^(EDAMNotebook *notebook) {
                // local (pull, add, push)
                NSMutableArray *arrNotebooks = [NSMutableArray arrayWithArray:[[[Storage sharedInstance] pullData] objectForKey:@"notebooks"]];
                NSDictionary *dictNotebook = [NSDictionary dictionaryWithObjects:@[notebook.guid, notebook.name, notebook.stack, notebook.defaultNotebook] forKeys:@[@"notebookGuid", @"notebookName", @"notebookStackName", @"notebookDefault"]];
                [arrNotebooks addObject:dictNotebook];
                [[Storage sharedInstance] pushData:arrNotebooks forKey:@"notebooks"];
                
                // complete
                [self createNotebookIndexes:^(NSError *error) {
                    [Util showSimpleAlertWithMessage:@"Successful notebook creation" andButton:nil forSeconds:0.4];
                    completion(nil);
                }];
            } failure:^(NSError *error) {
                [Util showSimpleAlertWithMessage:@"Failed to create new notebook"];
                completion(error);
            }];
        });
    } else {
        completion([NSError errorWithDomain:@"Could not connect to Evernote" code:0 userInfo:nil]);
    }
}

#pragma mark - Notes
+ (void) createNote:(NSString *)title content:(NSString *)content notebookGuid:(NSString *)notebookGuid tagGuids:(NSArray *)tagGuids completion:(void (^)(NSError *error))completion {
    if ([self isConnected]) {
        // clean
        title = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        content = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
                   "<!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\">"
                   "<en-note>"
                   "%@"
                   "</en-note>",[content stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
        
        // remote
        EDAMNote *newNote = [[EDAMNote alloc] init];
        [newNote setTitle:title];
        [newNote setContent:content];
        [newNote setNotebookGuid:notebookGuid];
        [newNote setTagGuids:tagGuids];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            [[[ENSession sharedSession] primaryNoteStore] createNote:newNote success:^(EDAMNote *note) {
                // local (pull, add, push)
                NSMutableArray *arrNotes = [NSMutableArray arrayWithArray:[[[Storage sharedInstance]  pullData] objectForKey:@"notes"]];
                
                NSString *noteTitle = (note.title == nil) ? @"" : note.title;
                NSString *noteNotebookGuid = (note.notebookGuid == nil) ? @"" : note.notebookGuid;
                NSArray *noteTagGuids = (note.tagGuids == nil) ? @[] : note.tagGuids;
                
                NSDictionary *dictNote = [NSDictionary dictionaryWithObjects:@[note.guid, noteTitle, note.created, note.updated, noteNotebookGuid, noteTagGuids] forKeys:@[@"noteGuid", @"noteTitle", @"noteCreated", @"noteUpdated", @"noteNotebookGuid", @"noteTagGuids"]];
                [arrNotes addObject:dictNote];
                [[Storage sharedInstance] pushData:arrNotes forKey:@"notes"];
                
                // complete
                [Evernote createNoteIndexes:^(NSError *error) {
                    [Util showSimpleAlertWithMessage:@"Successful note creation" andButton:nil forSeconds:0.4];
                    completion(nil);
                }];
                
            } failure:^(NSError *error) {
                [Util showSimpleAlertWithMessage:@"Failed to create new note"];
                completion(error);
            }];
        });
    } else {
        completion([NSError errorWithDomain:@"Could not connect to Evernote" code:0 userInfo:nil]);
    }
}

// only noteGuid is required
+ (void) updateNote:(NSString *)noteGuid title:(NSString *)title content:(NSString *)content notebookGuid:(NSString *)notebookGuid tagGuids:(NSArray *)tagGuids completion:(void (^)(NSError *error))completion {
    NSLog(@"evernote update note");
    if ([self isConnected]) {
        // clean
        title = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        content = [content stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        notebookGuid = [notebookGuid stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        noteGuid = [noteGuid stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                
        // remote
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // download note
            [[[ENSession sharedSession] primaryNoteStore] getNoteWithGuid:noteGuid withContent:YES withResourcesData:YES withResourcesRecognition:YES withResourcesAlternateData:YES success:^(EDAMNote *note) {
                
                EDAMNote *updateNote = note;
                [updateNote setTitle:(title == nil) ? note.title : title];
                [updateNote setContent:(content == nil) ? note.content : content];
                [updateNote setNotebookGuid:(notebookGuid == nil) ? note.notebookGuid : notebookGuid];
                [updateNote setTagGuids:(tagGuids == nil) ? note.tagGuids : tagGuids];
                
                // TODO: content
                // cannot handle #import <Foundation/Foundation.h>
                // en-todo to [] adn <en-todo checked="true"> [x]  ... then convert back
                
                // upload new note
                [[[ENSession sharedSession] primaryNoteStore] updateNote:updateNote success:^(EDAMNote *note) {
                    // local (pull, remove, add, push)
                    NSMutableArray *arrNotes = [NSMutableArray arrayWithArray:[[[Storage sharedInstance] pullData] objectForKey:@"notes"]];
                    // remove
                    for (int i = 0; i < [arrNotes count]; i++) {
                        if ([arrNotes[i][@"noteGuid"] isEqualToString:note.guid]) {
                            [arrNotes removeObjectAtIndex:i];
                            break;
                        }
                    }
                    // add
                    NSDictionary *dictNote = [NSDictionary dictionaryWithObjects:@[note.guid, note.title, note.created, note.updated, note.notebookGuid, (note.tagGuids == nil) ? @[] : note.tagGuids, (note.content == nil) ? @"" : note.content] forKeys:@[@"noteGuid", @"noteTitle", @"noteCreated", @"noteUpdated", @"noteNotebookGuid", @"noteTagGuids", @"noteContent"]];
                    [arrNotes addObject:dictNote];
                    [[Storage sharedInstance] pushData:arrNotes forKey:@"notes"];
                    
                    // complete
                    [Evernote createNoteIndexes:^(NSError *error) {
                        completion(nil);
                    }];
                } failure:^(NSError *error) {
                    [Util showSimpleAlertWithMessage:@"Failed to update note"];
                    completion(error);
                }];
            } failure:^(NSError *error) {
                [Util showSimpleAlertWithMessage:@"Failed to update note"];
                completion(error);
            }];
        });
    } else {
        completion([NSError errorWithDomain:@"Could not connect to Evernote" code:0 userInfo:nil]);
    }
}

+ (void) deleteNote:(NSString *)noteGuid completion:(void (^)(NSError *error))completion {
    // TODO: need to send array of note guids
    NSLog(@"evernote delete note");
    if ([self isConnected]) {
        // clean
        noteGuid = [noteGuid stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        // remote
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // download note
            [[[ENSession sharedSession] primaryNoteStore] deleteNoteWithGuid:noteGuid success:^(int32_t usn) {
                // local (pull, remove, push)
                NSMutableArray *arrNotes = [NSMutableArray arrayWithArray:[[[Storage sharedInstance] pullData] objectForKey:@"notes"]];
                for (NSInteger i = 0; i < [arrNotes count]; i++) {
                    if ([arrNotes[i][@"noteGuid"] isEqualToString:noteGuid]) {
                        [arrNotes removeObjectAtIndex:i];
                        break;
                    }
                }
                [[Storage sharedInstance] pushData:arrNotes forKey:@"notes"];
                
                // complete
                
                // TODO: should create indexes after all delete
                [Evernote createNoteIndexes:^(NSError *error) {
                    completion(nil);
                }];
            } failure:^(NSError *error) {
                [Util showSimpleAlertWithMessage:@"Failed to delete note"];
                completion(error);
            }];
        });
    } else {
        completion([NSError errorWithDomain:@"Could not connect to Evernote" code:0 userInfo:nil]);
    }
}

#pragma  mark - indexes
+ (void) createTagIndexes:(void (^)(NSError *error))completion {
    // pull data
    NSArray *arrTags = [[[Storage sharedInstance] pullData] objectForKey:@"tags"];
    
    // pull indexes
    NSMutableDictionary *indexes = [NSMutableDictionary dictionaryWithDictionary:[[[Storage sharedInstance] pullData] objectForKey:@"indexes"]];
    
    // create sortTagsByName index
    NSArray *sortTagsByName = [arrTags sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"tagName" ascending:YES selector:@selector(caseInsensitiveCompare:)]]];
    NSMutableArray *sortTagLocationsByName = [NSMutableArray array];
    for (NSDictionary *sortedTag in sortTagsByName) {
        [sortTagLocationsByName addObject:@[sortedTag[@"tagName"],[NSNumber numberWithInteger:[arrTags indexOfObject:sortedTag]]]];
    }
    [indexes setObject:sortTagLocationsByName forKey:@"sortTagsByName"];
    
    // create sortTagsByGuid index
    NSArray *sortTagsByGuid = [arrTags sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"tagGuid" ascending:YES selector:@selector(caseInsensitiveCompare:)]]];
    NSMutableArray *sortTagLocationsByGuids = [NSMutableArray array];
    for (NSDictionary *sortedTag in sortTagsByGuid) {
        [sortTagLocationsByGuids addObject:@[sortedTag[@"tagGuid"],[NSNumber numberWithInteger:[arrTags indexOfObject:sortedTag]]]];
    }
    [indexes setObject:sortTagLocationsByGuids forKey:@"sortTagsByGuid"];
    
    // create groupTagsByTagParentGuid index
    NSMutableArray *groupTagsByTagParentGuid = [NSMutableArray array];
    for (NSDictionary *tagGuid in sortTagsByGuid) {
        // sort by tag guid
        [groupTagsByTagParentGuid addObject:[NSMutableArray arrayWithObject:tagGuid[@"tagGuid"]]];
    }
    
    for (NSInteger i = 0; i < arrTags.count; i++) {
        // add location
        for (NSInteger j = 0; j < groupTagsByTagParentGuid.count; j++) {
            if ([arrTags[i][@"tagParentGuid"] isEqualToString:groupTagsByTagParentGuid[j][0]]) {
                [groupTagsByTagParentGuid[j] addObject:[NSNumber numberWithInteger:i]];
                break;
            }
        }
    }
    [indexes setObject:groupTagsByTagParentGuid forKey:@"groupTagsByTagParentGuid"];
    
    // store indexes
    [[Storage sharedInstance] pushData:indexes forKey:@"indexes"];
    
    completion(nil);
}

+ (void) createNotebookIndexes:(void (^)(NSError *error))completion {
    // pull data
    NSArray *arrNotebooks = [[[Storage sharedInstance] pullData] objectForKey:@"notebooks"];
    
    // pull indexes
    NSMutableDictionary *indexes = [NSMutableDictionary dictionaryWithDictionary:[[[Storage sharedInstance] pullData] objectForKey:@"indexes"]];
    
    // create sortNotebookByName index
    NSArray *sortNotebooksByName = [arrNotebooks sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"notebookName" ascending:YES selector:@selector(caseInsensitiveCompare:)]]];
    NSMutableArray *sortNotebookLocationsByName = [NSMutableArray array];
    for (NSDictionary *sortedNotebook in sortNotebooksByName) {
        [sortNotebookLocationsByName addObject:@[sortedNotebook[@"notebookName"],[NSNumber numberWithInteger:[arrNotebooks indexOfObject:sortedNotebook]]]];
    }
    [indexes setObject:sortNotebookLocationsByName forKey:@"sortNotebooksByName"];
    
    // create sortNotebooksByGuid index
    NSArray *sortNotebooksByGuid = [arrNotebooks sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"notebookGuid" ascending:YES selector:@selector(caseInsensitiveCompare:)]]];
    NSMutableArray *sortNotebookLocationsByGuid = [NSMutableArray array];
    for (NSDictionary *sortedNotebook in sortNotebooksByGuid) {
        [sortNotebookLocationsByGuid addObject:@[sortedNotebook[@"notebookGuid"],[NSNumber numberWithInteger:[arrNotebooks indexOfObject:sortedNotebook]]]];
    }
    [indexes setObject:sortNotebookLocationsByGuid forKey:@"sortNotebooksByGuid"];
    
    // create groupNotebooksByStackName index
    NSMutableArray *sortNotebookStacksByName = [NSMutableArray array];
    for (NSDictionary *notebookDictionary in sortNotebooksByName) {
        // sort by stack name
        if ([sortNotebookStacksByName indexOfObject:notebookDictionary[@"notebookStackName"]] == NSNotFound) {
            [sortNotebookStacksByName addObject:notebookDictionary[@"notebookStackName"]];
        }
    }
    sortNotebookStacksByName = [NSMutableArray arrayWithArray:[sortNotebookStacksByName sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
    
    NSMutableArray *groupNotebooksByStackName = [NSMutableArray array];
    for (NSString *notebookStack in sortNotebookStacksByName) {
        // make into 2d array
        [groupNotebooksByStackName addObject:[NSMutableArray arrayWithObject:notebookStack]];
    }
    for (NSInteger i = 0; i < arrNotebooks.count; i++) {
        // add locations
        for (NSInteger j = 0; j < groupNotebooksByStackName.count; j++) {
            if ([arrNotebooks[i][@"notebookStackName"] isEqualToString:groupNotebooksByStackName[j][0]]) {
                [groupNotebooksByStackName[j] addObject:[NSNumber numberWithInteger:i]];
                break;
            }
        }
    }
    [indexes setObject:groupNotebooksByStackName forKey:@"groupNotebooksByStackName"];
    
    // store indexes
    [[Storage sharedInstance] pushData:indexes forKey:@"indexes"];
    
    completion(nil);
}

+ (void) createNoteIndexes:(void (^)(NSError *error))completion {
    // pull data
    NSArray *arrNotes = [[[Storage sharedInstance] pullData] objectForKey:@"notes"];
    
    // pull indexes
    NSMutableDictionary *indexes = [NSMutableDictionary dictionaryWithDictionary:[[[Storage sharedInstance] pullData] objectForKey:@"indexes"]];
    
    // create sortNotesByTitle index
    NSArray *sortNotesByName = [arrNotes sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"noteTitle" ascending:YES selector:@selector(caseInsensitiveCompare:)]]];
    NSMutableArray *sortNoteLocationsByName = [NSMutableArray array];
    for (NSDictionary *sortedNote in sortNotesByName) {
        [sortNoteLocationsByName addObject:@[sortedNote[@"noteTitle"],[NSNumber numberWithInteger:[arrNotes indexOfObject:sortedNote]]]];
    }
    [indexes setObject:sortNoteLocationsByName forKey:@"sortNotesByTitle"];
    
    // create sortNotesByGuids index
    NSArray *sortNotesByGuid = [arrNotes sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"noteGuid" ascending:YES selector:@selector(caseInsensitiveCompare:)]]];
    NSMutableArray *sortNoteLocationsByGuid = [NSMutableArray array];
    for (NSDictionary *sortedNote in sortNotesByGuid) {
        [sortNoteLocationsByGuid addObject:@[sortedNote[@"noteGuid"],[NSNumber numberWithInteger:[arrNotes indexOfObject:sortedNote]]]];
    }
    [indexes setObject:sortNoteLocationsByGuid forKey:@"sortNotesByGuid"];
    
    // create sortNotesByUpdated index
    NSArray *sortNotesByUpdated = [arrNotes sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"noteUpdated" ascending:YES]]];
    NSMutableArray *sortNoteLocationsByUpdated = [NSMutableArray array];
    for (NSDictionary *sortedNote in sortNotesByUpdated) {
        [sortNoteLocationsByUpdated addObject:@[sortedNote[@"noteUpdated"],[NSNumber numberWithInteger:[arrNotes indexOfObject:sortedNote]]]];
    }
    [indexes setObject:sortNoteLocationsByUpdated forKey:@"sortNotesByUpdated"];
    
    // create groupNotesByTagGuid index
    NSMutableArray *sortTagsByGuid = [NSMutableArray arrayWithArray:[[[[Storage sharedInstance] pullData] objectForKey:@"indexes"] objectForKey:@"sortTagsByGuid"]];
    
    NSMutableArray *groupNotesByTagGuid  = [NSMutableArray array];
    for (NSInteger i = 0; i < sortTagsByGuid.count; i++) {
        // create array of tag locations (with the tagGuid at index 0)
        [groupNotesByTagGuid addObject:[NSMutableArray arrayWithObject:sortTagsByGuid[i][0]]];
    }
    
    for (NSInteger i = 0; i < arrNotes.count; i++) {
        // each note tag
        for (NSString *noteTagGuid in arrNotes[i][@"noteTagGuids"]) {
            // if exists in array of tags
            for (NSInteger j = 0; j < groupNotesByTagGuid.count; j++) {
                if ([noteTagGuid isEqualToString:groupNotesByTagGuid[j][0]]) {
                    [groupNotesByTagGuid[j] addObject:[NSNumber numberWithInteger:i]];
                    break;
                }
            }
        }
    }
    [indexes setObject:groupNotesByTagGuid forKey:@"groupNotesByTagGuid"];
    
    // create groupNotesByNotebookGuid index
    NSMutableArray *sortNotebooksByGuid = [NSMutableArray arrayWithArray:[[[[Storage sharedInstance] pullData] objectForKey:@"indexes"] objectForKey:@"sortNotebooksByGuid"]];
    
    NSMutableArray *groupNotesByNotebookGuid  = [NSMutableArray array];
    for (NSInteger i = 0; i < sortNotebooksByGuid.count; i++) {
        [groupNotesByNotebookGuid addObject:[NSMutableArray arrayWithObject:sortNotebooksByGuid[i][0]]];
    }
    
    for (NSInteger i = 0; i < arrNotes.count; i++) {
        for (NSInteger j = 0; j < groupNotesByNotebookGuid.count; j++) {
            if ([arrNotes[i][@"noteNotebookGuid"] isEqualToString:groupNotesByNotebookGuid[j][0]]) {
                [groupNotesByNotebookGuid[j] addObject:[NSNumber numberWithInteger:i]];
                break;
            }
        }
    }
    [indexes setObject:groupNotesByNotebookGuid forKey:@"groupNotesByNotebookGuid"];
    
    // store indexes
    [[Storage sharedInstance] pushData:indexes forKey:@"indexes"];
    
    // add tag names and notebooks name to notes
    NSArray *notes = [[[Storage sharedInstance] pullData] objectForKey:@"notes"];
    NSMutableArray *newNotes = [NSMutableArray array];
    for (NSDictionary *noteDict in notes) {
        NSMutableDictionary *newNoteDict = [NSMutableDictionary dictionaryWithDictionary:noteDict];
        NSString *notebookName = [[Storage sharedInstance] getNotebookNameWithGuid:noteDict[@"noteNotebookGuid"]];
        NSMutableArray *tagNames = [NSMutableArray array];
        for (NSString *tagGuid in noteDict[@"noteTagGuids"]) {
            [tagNames addObject:[[Storage sharedInstance] getTagNameWithGuid:tagGuid]];
        }
        [newNoteDict setObject:tagNames forKey:@"noteTagNames"];
        [newNoteDict setObject:notebookName forKey:@"noteNotebookName"];
        [newNotes addObject:newNoteDict];
    }
    [[Storage sharedInstance] pushData:newNotes forKey:@"notes"];
    
    completion(nil);
}

@end
