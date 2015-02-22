//
//  MasterViewController.m
//  ThoughtTrack
//
//  Created by Ethan Neff on 1/12/15.
//  Copyright (c) 2015 ethanneff. All rights reserved.
//

#import "MasterViewController.h"
#import "Config.h"
#import "MenuView.h"
#import "AlertView.h"
#import "SettingsView.h"
#import "GoalsView.h"
#import "NotesTableView.h"
#import "LoadView.h"
#import "Util.h"
#import "NoteCreate.h"
#import "NoteView.h"
#import "Evernote.h"
#import "Storage.h"
#import "SVProgressHUD.h"

@interface MasterViewController () <UITextFieldDelegate, UITextViewDelegate, UIWebViewDelegate>

// all button navigation
//    21 Settings
//    22 Tasks
//    23 Goals
//    24 Notes
//    25 Add
//
//    32 Search
//    33 Search Count
//    34 Cancel
//    35 Trash
//    36 Sort
//    37 Refresh
//
//    38 input search
//    39 cancel search
//    40 confirm search
//
//    42 Username
//    43 Login
//
//    51 Filter - tag single selection
//    52 Filter - tag multiple selection
//    53 Filter - notebook single selection
//
//    61 Back/Cancel
//    62 Keyboard hide
//    63 Submit
//
//    71 create title
//    72 create body
//
//    81 cell id
//    82 cell arrow
//    83 cell title
//    84 cell detail
//    85 cell noteGuid
//
//    91 view title
//    92 view content

// menus
@property (nonatomic) MenuView *menuLoad;
@property (nonatomic) MenuView *menuSettings;
@property (nonatomic) MenuView *menuTasks;
@property (nonatomic) MenuView *menuGoals;
@property (nonatomic) MenuView *menuNotes;
@property (nonatomic) MenuView *menuTaskCreate;
@property (nonatomic) MenuView *menuNoteCreate;
@property (nonatomic) MenuView *menuNoteEdit;
@property (nonatomic) MenuView *menuNoteSearch;
@property (nonatomic) MenuView *menuNoteView;
@property (nonatomic) MenuView *menuGoalEdit;

@property (nonatomic) MenuView *menuLast;
@property (nonatomic) NSInteger menuTagLast;

// content
@property (nonatomic) AlertView *viewAlert;
@property (nonatomic) LoadView *viewLoad;
@property (nonatomic) SettingsView *viewSettings;
@property (nonatomic) GoalsView *viewGoals;
@property (nonatomic) NoteCreate *viewTaskCreate;
@property (nonatomic) NoteCreate *viewNoteCreate;
@property (nonatomic) NoteView *viewNoteView;
@property (nonatomic) NotesTableView *tableViewTasks;
@property (nonatomic) NotesTableView *tableViewNotes;

// data
@property (nonatomic) NSArray *filterWhere;
@property (nonatomic) NSArray *filterWhen;
@property (nonatomic) NSArray *filterWhat;
@property (nonatomic) NSArray *filterNotesbook;

@property (nonatomic) NSArray *tasks;
@property (nonatomic) NSArray *notes;

@property (nonatomic) SortType tasksSort;
@property (nonatomic) SortType notesSort;

@property (nonatomic) NSMutableDictionary *tasksFilters;
@property (nonatomic) NSMutableDictionary *notesFilters;
@property (nonatomic) NSMutableDictionary *noteFilters;

// cell
@property (nonatomic) UIView *cellPressed;
@property (nonatomic) NSString *cellNoteTitleLast;
@property (nonatomic) NSString *cellNoteContents;

// search
@property (nonatomic) BOOL tasksSearchTextfieldOverride;
@property (nonatomic) BOOL notesSearchTextfieldOverride;

@property (nonatomic) NSString *tasksSearchLast;
@property (nonatomic) NSString *notesSearchLast;

@end

@implementation MasterViewController

#pragma mark - load
- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"view did load (initial)");
    
    // third party
    [SVProgressHUD setBackgroundColor:[UIColor clearColor]];
    [SVProgressHUD setForegroundColor:[Config sharedInstance].colorBackground];
    [Util getNetworkStatus];
    
    // frame
    [self.view setBackgroundColor:[Config sharedInstance].colorBackground];
    [Config sharedInstance].frameHeight = self.view.frame.size.height;
    [Config sharedInstance].frameWidth  = self.view.frame.size.width;
    
    // scene
    [self createSubviews];
    
    // keyboard height notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    
    // TODO: make this after the tableview updates... instead of delay
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
        if ([Evernote isAuthenticated]) {
            [self evernotePullAll:^(NSError *error) {
                if (error) {
                    [self updateMenusWithData];
                }
            }];
        }
    });
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:YES];
}

- (void) viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    NSLog(@"view did layout subviews");
    
    // change in the status bar's height (such as navigation app or phone call)
    if ([Config sharedInstance].frameHeight != self.view.frame.size.height && [[Config sharedInstance] isAppOpen]) {
        [self menuResize];
    }
}

#pragma mark - views
-(void)createSubviews {
    NSLog(@"create subviews");
    // alert
    self.viewAlert = [AlertView create];
    [self.view addSubview:self.viewAlert.view];
    [self.viewAlert.view setHidden:YES];
    
    // input accessory views (not added to self.view)
    self.menuNoteSearch = [MenuView createContainer];
    [self.menuNoteSearch insertRowWithSize:1 withSeparator:NO];
    [self.menuNoteSearch updateRow:1 withSearch:SearchLocationInput withController:self];
    
    self.menuGoalEdit = [MenuView createContainer];
    [self.menuGoalEdit insertRowWithSize:1 withSeparator:NO];
    [self.menuGoalEdit updateRow:1 withCreate:self];
    
    self.menuTaskCreate = [MenuView createContainer];
    [self.menuTaskCreate insertRowWithSize:1 withSeparator:YES];
    [self.menuTaskCreate insertRowWithSize:1 withSeparator:YES];
    [self.menuTaskCreate insertRowWithSize:2 withSeparator:YES];
    [self.menuTaskCreate insertRowWithSize:1 withSeparator:NO];
    [self.menuTaskCreate updateRow:4 withCreate:self];
    
    self.menuNoteCreate = [MenuView createContainer];
    [self.menuNoteCreate insertRowWithSize:3 withSeparator:YES];
    [self.menuNoteCreate insertRowWithSize:1 withSeparator:NO];
    [self.menuNoteCreate updateRow:2 withCreate:self];
    
    self.menuNoteEdit = [MenuView createContainer];
    [self.menuNoteEdit insertRowWithSize:1 withSeparator:YES];
    [self.menuNoteEdit insertRowWithSize:1 withSeparator:YES];
    [self.menuNoteEdit insertRowWithSize:2 withSeparator:YES];
    [self.menuNoteEdit insertRowWithSize:2 withSeparator:YES];
    [self.menuNoteEdit insertRowWithSize:1 withSeparator:NO];
    [self.menuNoteEdit updateRow:5 withCreate:self];
    
    // menus
    self.menuLoad = [MenuView createContainer];
    [self.menuLoad insertRowWithSize:1 withSeparator:NO];
    [self.menuLoad updateRow:1 withNavigation:self];
    [self.view addSubview:self.menuLoad.view];
    
    self.menuSettings = [MenuView createContainer];
    [self.menuSettings insertRowWithSize:1 withSeparator:NO];
    [self.menuSettings updateRow:1 withSettings:self];
    [self.view addSubview:self.menuSettings.view];
    
    self.menuTasks = [MenuView createContainer];
    [self.menuTasks insertRowWithSize:1 withSeparator:YES];
    [self.menuTasks insertRowWithSize:1 withSeparator:YES];
    [self.menuTasks insertRowWithSize:2 withSeparator:YES];
    [self.menuTasks insertRowWithSize:1 withSeparator:YES];
    [self.menuTasks insertRowWithSize:1 withSeparator:NO];
    [self.menuTasks updateRow:4 withSearch:SearchLocationMenu withController:self];
    [self.menuTasks updateRow:5 withNavigation:self];
    [(UITextField *)[[self.menuTasks.view viewWithTag:4] viewWithTag: 32] setInputAccessoryView:self.menuNoteSearch.view];
    [self.view addSubview:self.menuTasks.view];
    
    self.menuGoals = [MenuView createContainer];
    [self.menuGoals insertRowWithSize:1 withSeparator:YES];
    [self.menuGoals insertRowWithSize:1 withSeparator:NO];
    [self.menuGoals updateRow:2 withNavigation:self];
    [self.view addSubview:self.menuGoals.view];
    
    self.menuNotes = [MenuView createContainer];
    [self.menuNotes insertRowWithSize:4 withSeparator:YES];
    [self.menuNotes insertRowWithSize:1 withSeparator:YES];
    [self.menuNotes insertRowWithSize:1 withSeparator:NO];
    [self.menuNotes updateRow:2 withSearch:SearchLocationMenu withController:self];
    [self.menuNotes updateRow:3 withNavigation:self];
    [(UITextField *)[[self.menuNotes.view viewWithTag:2] viewWithTag: 32] setInputAccessoryView:self.menuNoteSearch.view];
    [self.view addSubview:self.menuNotes.view];
    
    self.menuNoteView = [MenuView createContainer];
    [self.menuNoteView insertRowWithSize:1 withSeparator:YES];
    [self.menuNoteView insertRowWithSize:1 withSeparator:YES];
    [self.menuNoteView insertRowWithSize:2 withSeparator:YES];
    [self.menuNoteView insertRowWithSize:2 withSeparator:YES];
    [self.menuNoteView insertRowWithSize:1 withSeparator:NO];
    [self.menuNoteView updateRow:5 withCreate:self];
    [self.view addSubview:self.menuNoteView.view];
    
    // content (dependent on menu height)
    self.viewLoad = [LoadView createWithMenu:self.menuLoad.view];
    [self.view addSubview:self.viewLoad.view];
    
    self.viewSettings = [SettingsView createWithMenu:self.menuSettings.view];
    [self.view addSubview:self.viewSettings.view];
    
    self.tableViewTasks = [NotesTableView createWithMenu:self.menuTasks.view withController:self];
    [self.view addSubview:self.tableViewTasks.view];
    
    self.viewGoals = [GoalsView createWithMenu:self.menuGoalEdit.view withController:self];
    [self.view addSubview:self.viewGoals.view];
    
    self.tableViewNotes = [NotesTableView createWithMenu:self.menuNotes.view withController:self];
    [self.view addSubview:self.tableViewNotes.view];
    
    self.viewTaskCreate = [NoteCreate createWithMenu:self.menuTaskCreate.view withController:self];
    [self.view addSubview:self.viewTaskCreate.view];
    
    self.viewNoteCreate = [NoteCreate createWithMenu:self.menuNoteCreate.view withController:self];
    [self.view addSubview:self.viewNoteCreate.view];
    
    self.viewNoteView = [NoteView createWithMenu:self.menuNoteEdit.view withController:self];
    [self.view addSubview:self.viewNoteView.view];
    
    // properties load values
    self.tasksSort = SortTypeAZ;
    self.notesSort = SortTypeAZ;
    
    self.tasksFilters = [NSMutableDictionary dictionaryWithObjects:@[[NSMutableArray array], [NSMutableArray array], [NSString string], [NSMutableArray array]] forKeys:@[@"tagNames", @"notebookName", @"searchText", @"searchNoteGuids"]];
    self.notesFilters = [NSMutableDictionary dictionaryWithObjects:@[[NSMutableArray array], [NSMutableArray array], [NSString string], [NSMutableArray array]] forKeys:@[@"tagNames", @"notebookName", @"searchText", @"searchNoteGuids"]];
    self.noteFilters = [NSMutableDictionary dictionaryWithObjects:@[[NSMutableArray array], [NSMutableArray array], [NSString string], [NSMutableArray array]] forKeys:@[@"tagNames", @"notebookName", @"searchText", @"searchNoteGuids"]];
    
    // update with data
    [self updateViewLogin];
    [self updateMenusWithData];
    
    // load
    [self menuHide];
    [self.viewLoad.view setHidden:NO];
    [self.menuLoad.view setHidden:NO];
}

#pragma mark - data updates
-(void)evernotePullAll:(void (^)(NSError *error))completion {
    NSLog(@"evernote pull all");
    [self showActivityIndicators];
    [Evernote getAll:^(NSError *error) {
        [self dismissActivityIndicators];
        if (!error) {
            [self updateMenusWithData];
            completion(nil);
        } else {
            // TODO: alert and retry 3x
            completion(error);
        }
    }];
}

-(void)evernoteSearch:(UIButton *)button {
    NSString *searchText = [(UITextField *)[[self.menuNoteSearch.view viewWithTag:1] viewWithTag: 38] text];
    UITextField *menuTextfield;
    NSMutableDictionary *filters;
    if ([self menuCurrent] == self.menuTasks) {
        filters = self.tasksFilters;
        menuTextfield = (UITextField *)[[self.menuTasks.view viewWithTag:4] viewWithTag: 32];
    } else if ([self menuCurrent] == self.menuNotes) {
        filters = self.notesFilters;
        menuTextfield = (UITextField *)[[self.menuNotes.view viewWithTag:2] viewWithTag: 32];
    }
    
    [self buttonDisable:button];
    [self showActivityIndicators];
    NSLog(@"searhc: %@",searchText);
    [Evernote getNoteGuidsWithSearch:searchText completion:^(NSArray *noteGuids) {
        [self buttonEnable:button];
        [self dismissActivityIndicators];
        
        // successful
        if (noteGuids != nil) {
            // update the filters dictionary
            [filters setObject:searchText forKey:@"searchText"];
            [filters setObject:noteGuids forKey:@"searchNoteGuids"];
            
            // update tableview
            [self updateTableViews];
            
            // move textfield texts
            [menuTextfield setText:searchText];
            
            // reset textfield
            [self textFieldSetBorderColor:menuTextfield];
            
            // remove keyboard
            [(UITextField *)[[self.menuNoteSearch.view viewWithTag:1] viewWithTag: 38] resignFirstResponder];
            [self dismissKeyboard];
        }
    }];
}

#pragma mark - view updates
-(void)updateViewLogin {
    if ([Evernote isAuthenticated]) {
        [(UILabel *)[self.menuSettings.view viewWithTag:42] setText:[[Storage sharedInstance] getUsername]];
        [(UIButton *)[self.menuSettings.view viewWithTag:43] setTitle:@"Logout" forState:UIControlStateNormal];
    } else {
        [(UILabel *)[self.menuSettings.view viewWithTag:42] setText:@""];
        [(UIButton *)[self.menuSettings.view viewWithTag:43] setTitle:@"Login" forState:UIControlStateNormal];
    }
}

-(void)updateMenusWithData {
    NSLog(@"update menus with data");
    // properties
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // properties
        self.filterWhere = [[Storage sharedInstance] getTagNamesFromTagParentName:@".Where"];
        self.filterWhen = [[Storage sharedInstance] getTagNamesFromTagParentName:@".When"];
        self.filterWhat = [[Storage sharedInstance] getTagNamesAll];
        NSMutableArray *newFilterWhat = [NSMutableArray array];
        if (self.filterWhat != nil) {
            for (NSString *filter in self.filterWhat) {
                (![[filter substringToIndex:1] isEqualToString:@"."] && [self.filterWhere indexOfObject:filter] == NSNotFound && [self.filterWhen indexOfObject:filter] == NSNotFound) ? [newFilterWhat addObject:filter] : nil;
            }
            self.filterWhat = [newFilterWhat sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        }
        
        self.filterNotesbook = [[Storage sharedInstance] getNotebookNamesAll];
        
        // views
        dispatch_async(dispatch_get_main_queue(), ^(void){
            // update tableviews
            [self refreshFields];
            [self updateTableViews];
        });
    });
}

-(void)updateTableViews {
    NSLog(@"update table views");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // fill the local arrays
        NSMutableArray *taskTagGuids = [NSMutableArray array];
        for (NSString *tagName in self.tasksFilters[@"tagNames"]) {
            [taskTagGuids addObject:[[Storage sharedInstance] getTagGuidWithName:tagName]];
        }
        self.tasks = [[[Storage sharedInstance] getNotesWithNoteGuids:self.tasksFilters[@"searchNoteGuids"] notebookGuids:@[[[Storage sharedInstance] getNotebookGuidWithName:@"Actions Pending"]] tagGuids:taskTagGuids sortType:self.tasksSort] arrayByAddingObjectsFromArray:[[Storage sharedInstance] getNotesWithNoteGuids:self.tasksFilters[@"searchNoteGuids"] notebookGuids:@[[[Storage sharedInstance] getNotebookGuidWithName:@"Completed"]] tagGuids:taskTagGuids sortType:self.tasksSort]];
        
        NSString *noteNotebookGuid = [[Storage sharedInstance] getNotebookGuidWithName:[self.notesFilters[@"notebookName"] firstObject]];
        self.notes = [[Storage sharedInstance] getNotesWithNoteGuids:self.notesFilters[@"searchNoteGuids"] notebookGuids:(noteNotebookGuid == nil) ? nil : @[noteNotebookGuid] tagGuids:nil  sortType:self.notesSort];
        
        // update the tableviews data
        self.tableViewTasks.data = self.tasks;
        self.tableViewNotes.data = self.notes;
        
        // update the tableviews views
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self.tableViewTasks.tableView reloadData];
            [(UILabel *)[self.menuTasks.view viewWithTag:33] setText:[NSString stringWithFormat:@"%lu", (unsigned long)self.tasks.count]];
            
            [self.tableViewNotes.tableView reloadData];
            [(UILabel *)[self.menuNotes.view viewWithTag:33] setText:[NSString stringWithFormat:@"%lu", (unsigned long)self.notes.count]];
            [self dismissActivityIndicators];
        });
    });
}

-(void)updateCellSwipeRight:(id)sender {
    NSLog(@"swipe right");
    // pull the cell's title
    UITableViewCell *cell = (UITableViewCell *)[sender view];
    UITextField *title = (UITextField *)[cell viewWithTag:83];
    
    // only change if not completed
    if ([title.textColor isEqual:[Config sharedInstance].colorBackground]) {
        // change the cell's title attributes
        NSAttributedString *strikeThrough = [[NSAttributedString alloc] initWithString:title.text attributes:@{NSStrikethroughStyleAttributeName:[NSNumber numberWithInteger:NSUnderlineStyleSingle]}];
        title.attributedText = strikeThrough;
        title.textColor = [Config sharedInstance].colorOutline;
        
        // pull the cell's data
        NSString *noteGuid = [(UILabel *)[cell viewWithTag:85] text];
        NSString *notebookGuid = [[Storage sharedInstance] getNotebookGuidWithName:@"Completed"];
        
        // update evernote, storage, and tableview
        [self showActivityIndicators];
        [Evernote updateNote:noteGuid title:nil content:nil notebookGuid:notebookGuid tagGuids:nil completion:^(NSError *error) {
            [self dismissActivityIndicators];
            if (!error) {
                [self updateTableViews];
            } else {
                NSAttributedString *strikeThrough = [[NSAttributedString alloc] initWithString:title.text attributes:@{NSStrikethroughStyleAttributeName:[NSNumber numberWithInteger:NSUnderlineStyleSingle]}];
                title.text = [strikeThrough string];
                title.textColor = [Config sharedInstance].colorBackground;
            }
        }];
    }
}

-(void)updateCellSwipeLeft:(id)sender {
    NSLog(@"swipe left");
    
    // pull the cell's title
    UITableViewCell *cell = (UITableViewCell *)[sender view];
    UITextField *title = (UITextField *)[cell viewWithTag:83];
    
    // only change if not completed
    if ([title.textColor isEqual:[Config sharedInstance].colorOutline]) {
        // change the cell's title attributes
        
        NSAttributedString *strikeThrough = [[NSAttributedString alloc] initWithString:title.text attributes:@{NSStrikethroughStyleAttributeName:[NSNumber numberWithInteger:NSUnderlineStyleSingle]}];
        title.text = [strikeThrough string];
        title.textColor = [Config sharedInstance].colorBackground;
        
        // pull the cell's data
        NSString *noteGuid = [(UILabel *)[cell viewWithTag:85] text];
        NSString *notebookGuid = [[Storage sharedInstance] getNotebookGuidWithName:@"Actions Pending"];
        
        // update evernote, storage, and tableview
        [self showActivityIndicators];
        [Evernote updateNote:noteGuid title:nil content:nil notebookGuid:notebookGuid tagGuids:nil completion:^(NSError *error) {
            [self dismissActivityIndicators];
            if (!error) {
                [self updateTableViews];
            } else {
                NSAttributedString *strikeThrough = [[NSAttributedString alloc] initWithString:title.text attributes:@{NSStrikethroughStyleAttributeName:[NSNumber numberWithInteger:NSUnderlineStyleSingle]}];
                title.attributedText = strikeThrough;
                title.textColor = [Config sharedInstance].colorOutline;
            }
        }];
    }
}

-(void)updateNoteEdit:(UITextField *)textField {
    NSLog(@"update note edit");
    // store property (for update note submit)
    self.cellPressed = [textField superview];
    
    // set accessory view
    [[self menuCurrent].view setHidden:YES];
    [textField setInputAccessoryView:self.menuNoteEdit.view];
    [self.menuNoteEdit.view setHidden:NO];
    
    // fill accessory view (pull from self.tasks and self.notes)
    NSDictionary *note = [[[Storage sharedInstance] getNotesWithNoteGuids:@[[(UILabel *)[[textField superview] viewWithTag:85] text]] notebookGuids:nil tagGuids:nil sortType:SortTypeAZ] firstObject];
    
    NSMutableArray *tags = note[@"noteTagNames"];
    NSString *notebook = note[@"noteNotebookName"];
    UIView *row;
    // tags
    for (NSInteger i = 1 ; i <= 3; i++) {
        row = [self.menuNoteEdit.view viewWithTag:i];
        for (UIButton *filter in [row subviews]) {
            if (![filter isKindOfClass:[UIImageView class]]) {
                NSInteger index = [tags indexOfObject:filter.titleLabel.text];
                if (index != NSNotFound) {
                    [filter setSelected:YES];
                    [filter.layer setBorderColor:[[Config sharedInstance].colorSelected CGColor]];
                    [self.noteFilters[@"tagNames"] addObject:filter.titleLabel.text];
                }
            }
        }
    }
    // notebook
    row = [self.menuNoteEdit.view viewWithTag:4];
    for (UIButton *filter in [row subviews]) {
        if (![filter isKindOfClass:[UIImageView class]]) {
            if (notebook == filter.titleLabel.text) {
                [filter setSelected:YES];
                [filter.layer setBorderColor:[[Config sharedInstance].colorOutline CGColor]];
                [self.noteFilters[@"notebookName"] addObject:filter.titleLabel.text];
            }
        }
    }
    // resize tableview (timed for keyboard animation to go up)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, .2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
        // select tableview
        UITableView *tableView;
        if (self.menuTagLast == 22) {
            tableView = self.tableViewTasks.tableView;
        } else if (self.menuTagLast == 24) {
            tableView = self.tableViewNotes.tableView;
        }
        dispatch_async(dispatch_get_main_queue(), ^(void){
            // resize tableview to smaller
            CGRect rectContent = tableView.frame;
            rectContent.size.height = [Config sharedInstance].frameHeight - [Config sharedInstance].keyboardHeight - [Config sharedInstance].statusBarHeight;
            tableView.frame = rectContent;
            
            // scroll to the cell
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[[(UILabel *)[[textField superview] viewWithTag:81] text] intValue] inSection:0];
            [tableView scrollToRowAtIndexPath: indexPath atScrollPosition: UITableViewScrollPositionBottom animated: YES];
        });
    });
}

#pragma mark - buttons
- (void) buttonTap:(UIButton *)button {
    // log
    NSLog(@"button: %@ row %li", button.titleLabel.text, (long)button.tag);
    
    // change button seletion
    button.selected = !button.selected;
    (button.selected) ? [button.layer setBorderColor:[[Config sharedInstance].colorSelected CGColor]] : [button.layer setBorderColor:[[Config sharedInstance].colorOutline CGColor]];
    
    // main navigation
    if (button.tag > 20 && button.tag < 30) {
        [self menuNavigation:button.tag];
    }
    // login
    else if (button.tag == 43) {
        [self menuLogin:button];
    }
    // filter
    else if (button.tag == 51 || button.tag == 52 || button.tag == 53) {
        [self filterTap:button];
    }
    // cancel
    else if (button.tag == 34) {
        [self menuCancel:button];
    }
    // trash
    else if (button.tag == 35) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Are you sure you want to delete ALL completed notes?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes",nil];
        [alert show];
    }
    // sort
    else if (button.tag == 36) {
        [self sort:button];
    }
    // refresh
    else if (button.tag == 37) {
        [self buttonDisable:button];
        [self evernotePullAll:^(NSError *error) {
            [self buttonEnable:button];
        }];
    }
    // cancel or submit
    else if (button.tag == 61 || button.tag == 63) {
        [self menuConfirm:button];
    }
    // search cancel
    else if (button.tag == 39) {
        button.selected = !button.selected;
        [(UITextField *)[[self.menuNoteSearch.view viewWithTag:1] viewWithTag: 38] resignFirstResponder];
        [self dismissKeyboard];
    }
    // search commit
    else if (button.tag == 40) {
        [self evernoteSearch:button];
    }
    // cell view note
    else if (button.tag == 82) {
        [self menuCell:button];
    }
}

-(void)buttonEnable:(UIButton *)button {
    button.selected = NO;
    [button setUserInteractionEnabled:YES];
}

-(void)buttonDisable:(UIButton *)button {
    button.selected = YES;
    [button setUserInteractionEnabled:NO];
}


#pragma mark - menu navigation
-(void)menuNavigation:(NSInteger)buttonTag {
    [self menuHide];
    
    if (buttonTag == 21) {
        [self.menuSettings.view setHidden:NO];
        [self.viewSettings.view setHidden:NO];
    } else if (buttonTag == 22) {
        [self.menuTasks.view setHidden:NO];
        [self.tableViewTasks.view setHidden:NO];
        [self menuNavigationSelect:self.menuTasks tag:22];
    } else if (buttonTag == 23) {
        [self.menuGoals.view setHidden:NO];
        [self.viewGoals.view setHidden:NO];
        [self menuNavigationSelect:self.menuGoals tag:23];
    } else if (buttonTag == 24) {
        [self.menuNotes.view setHidden:NO];
        [self.tableViewNotes.view setHidden:NO];
        [self menuNavigationSelect:self.menuNotes tag:24];
    } else if (buttonTag == 25) {
        if (self.menuTagLast == 0 || self.menuTagLast == 22) {
            [self.viewTaskCreate.view setHidden:NO];
            [self.menuTaskCreate.view setHidden:NO];
            [(UITextField *)[self.viewTaskCreate.view viewWithTag:71] becomeFirstResponder];
        } else if (self.menuTagLast == 24) {
            [self.viewNoteCreate.view setHidden:NO];
            [self.menuNoteCreate.view setHidden:NO];
            [(UITextField *)[self.viewNoteCreate.view viewWithTag:71] becomeFirstResponder];
        } else {
            [self menuNavigation:self.menuTagLast];
        }
    } else if (buttonTag == 0 || buttonTag ==  29){
        [self.menuLoad.view setHidden:NO];
        [self.viewLoad.view setHidden:NO];
        [self menuNavigationSelect:self.menuLoad tag:0];
    }
    
    if (buttonTag == 22 || buttonTag == 23 || buttonTag == 24) {
        self.menuLast = [self menuCurrent];
        self.menuTagLast = buttonTag;
    }
}

-(MenuView *)menuCurrent {
    if (!self.menuLoad.view.hidden) {
        return self.menuLoad;
    } else if (!self.menuSettings.view.hidden) {
        return self.menuSettings;
    } else if (!self.menuTasks.view.hidden) {
        return self.menuTasks;
    } else if (!self.menuGoals.view.hidden) {
        return self.menuGoals;
    } else if (!self.menuNotes.view.hidden) {
        return self.menuNotes;
    } else if (!self.menuTaskCreate.view.hidden) {
        return self.menuTaskCreate;
    } else if (!self.menuNoteCreate.view.hidden) {
        return self.menuNoteCreate;
    } else if (!self.menuNoteEdit.view.hidden) {
        return self.menuNoteEdit;
    } else if (!self.menuNoteSearch.view.hidden) {
        return self.menuNoteSearch;
    } else if (!self.menuNoteView.view.hidden) {
        return self.menuNoteView;
    }
    return self.menuLoad;
}

-(void)menuHide {
    [self.menuLoad.view setHidden:YES];
    [self.menuSettings.view setHidden:YES];
    [self.menuTasks.view setHidden:YES];
    [self.menuGoals.view setHidden:YES];
    [self.menuNotes.view setHidden:YES];
    [self.menuTaskCreate.view setHidden:YES];
    [self.menuNoteCreate.view setHidden:YES];
   	[self.menuNoteEdit.view setHidden:YES];
    [self.menuNoteSearch.view setHidden:YES];
    [self.menuNoteView.view setHidden:YES];
    
    [self.viewLoad.view setHidden:YES];
    [self.viewSettings.view setHidden:YES];
    [self.tableViewTasks.view setHidden:YES];
    [self.viewGoals.view setHidden:YES];
    [self.tableViewNotes.view setHidden:YES];
    [self.viewTaskCreate.view setHidden:YES];
    [self.viewNoteCreate.view setHidden:YES];
    [self.viewNoteView.view setHidden:YES];
}

-(void)menuNavigationSelect:(MenuView *)menuView tag:(NSInteger)tag {
    [(UIButton *)[[self.menuSettings.view viewWithTag:1] viewWithTag:26] setSelected:NO];
    [(UIButton *)[[self.menuTaskCreate.view viewWithTag:self.menuTaskCreate.numOfRows] viewWithTag:26] setSelected:NO];
    [(UIButton *)[[self.menuNoteCreate.view viewWithTag:self.menuNoteCreate.numOfRows] viewWithTag:26] setSelected:NO];
    [(UIButton *)[[self.menuNoteEdit.view viewWithTag:self.menuNoteEdit.numOfRows] viewWithTag:26] setSelected:NO];
    
    [(UIButton *)[[menuView.view viewWithTag:menuView.numOfRows] viewWithTag:21] setSelected:NO];
    [(UIButton *)[[menuView.view viewWithTag:menuView.numOfRows] viewWithTag:22] setSelected:NO];
    [(UIButton *)[[menuView.view viewWithTag:menuView.numOfRows] viewWithTag:23] setSelected:NO];
    [(UIButton *)[[menuView.view viewWithTag:menuView.numOfRows] viewWithTag:24] setSelected:NO];
    [(UIButton *)[[menuView.view viewWithTag:menuView.numOfRows] viewWithTag:25] setSelected:NO];
    
    (tag > 0) ? [(UIButton *)[[menuView.view viewWithTag:menuView.numOfRows] viewWithTag:tag] setSelected:YES] : nil;
}

-(void)menuLogin:(UIButton *)button {
    if ([button.titleLabel.text isEqualToString:@"Login"]) {
        [Evernote login:self completion:^(NSError *error) {
            if (!error) {
                [self updateViewLogin];
                [self evernotePullAll:^(NSError *error) {}];
            }
        }];
    } else if ([button.titleLabel.text isEqualToString:@"Logout"])  {
        [Evernote logout];
        [self updateViewLogin];
        [self dismissActivityIndicators];
    }
    [button setSelected:NO];
}

-(void)menuConfirm:(UIButton *)button {
    // submit
    if (button.tag == 63 && [self menuCurrent] != self.menuGoals) {
        [self buttonDisable:button];
        if ([self menuCurrent] == self.menuTaskCreate) {
            NSLog(@"taskcreate");
            // pull
            NSString *title = [[(UITextField *)[self.viewTaskCreate.view viewWithTag:71] text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSString *content = [[(UITextView *)[self.viewTaskCreate.view viewWithTag:72] text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            // validate
            if (title.length == 0) {
                [Util showSimpleAlertWithMessage:@"Note must have a title"];
                [self buttonEnable:button];
            } else if (title.length > 249) {
                [Util showSimpleAlertWithMessage:@"Note title cannot be longer than 250"];
                [self buttonEnable:button];
            } else if ([self.noteFilters[@"tagNames"] count] == 0) {
                [Util showSimpleAlertWithMessage:@"Note must have at least one category filter"];
                [self buttonEnable:button];
            } else {
                // create note
                NSString *notebookGuid = [[Storage sharedInstance] getNotebookGuidWithName:@"Actions Pending"];
                NSMutableArray *tagGuids = [NSMutableArray array];
                for (NSString *tagName in self.noteFilters[@"tagNames"]) {
                    [tagGuids addObject:[[Storage sharedInstance] getTagGuidWithName:tagName]];
                }
                
                [self showActivityIndicators];
                [Evernote createNote:title content:content notebookGuid:notebookGuid tagGuids:tagGuids completion:^(NSError *error) {
                    [self dismissActivityIndicators];
                    [self buttonEnable:button];
                    if (!error) {
                        [self menuNavigation:self.menuTagLast];
                        [self updateTableViews];
                        [self resetFields];
                    }
                }];
            }
        } else if ([self menuCurrent] == self.menuNoteCreate) {
            NSLog(@"notecreate");
            // pull
            NSString *title = [[(UITextField *)[self.viewNoteCreate.view viewWithTag:71] text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSString *content = [[(UITextView *)[self.viewNoteCreate.view viewWithTag:72] text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            // validate
            if (title.length == 0) {
                [Util showSimpleAlertWithMessage:@"Note must have a title"];
                [self buttonEnable:button];
            } else if (title.length > 249) {
                [Util showSimpleAlertWithMessage:@"Note title cannot be longer than 250"];
                [self buttonEnable:button];
            } else if ([self.noteFilters[@"notebookName"] count] == 0) {
                [Util showSimpleAlertWithMessage:@"Note must have at least one notebook"];
                [self buttonEnable:button];
            } else {
                // create note
                NSString *notebookGuid = [[Storage sharedInstance] getNotebookGuidWithName:[self.noteFilters[@"notebookName"] firstObject]];
                
                [self showActivityIndicators];
                [Evernote createNote:title content:content notebookGuid:notebookGuid tagGuids:nil completion:^(NSError *error) {
                    [self dismissActivityIndicators];
                    [self buttonEnable:button];
                    if (!error) {
                        [self menuNavigation:self.menuTagLast];
                        [self updateTableViews];
                        [self resetFields];
                    }
                }];
            }
        } else if ([self menuCurrent] == self.menuNoteEdit) {
            // tasks
            if (self.menuTagLast == 22) {
                NSLog(@"task edit");
                // pull
                NSString *noteGuid = [[(UILabel *)[self.cellPressed viewWithTag:85] text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                NSString *notetitle = [[(UITextField *)[self.cellPressed viewWithTag:83] text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];;
                // validate
                if (notetitle.length == 0) {
                    [Util showSimpleAlertWithMessage:@"Note must have a title"];
                    [self buttonEnable:button];
                } else if (notetitle.length > 249) {
                    [Util showSimpleAlertWithMessage:@"Note title cannot be longer than 250"];
                    [self buttonEnable:button];
                } else if ([self.noteFilters[@"notebookName"] count] == 0) {
                    [Util showSimpleAlertWithMessage:@"Note must have at least one notebook"];
                    [self buttonEnable:button];
                } else if ([self.noteFilters[@"tagNames"] count] == 0) {
                    [Util showSimpleAlertWithMessage:@"Note must have at least one category filter"];
                    [self buttonEnable:button];
                } else {
                    // update note
                    NSString *notebookGuid = [[Storage sharedInstance] getNotebookGuidWithName:[self.noteFilters[@"notebookName"] firstObject]];
                    NSMutableArray *tagGuids;
                    for (NSString *tagName in self.noteFilters[@"tagNames"]) {
                        // if there are no tags selected before
                        (tagGuids == nil) ? tagGuids = [NSMutableArray array] : nil;
                        [tagGuids addObject:[[Storage sharedInstance] getTagGuidWithName:tagName]];
                    }
                    
                    [self showActivityIndicators];
                    [Evernote updateNote:noteGuid title:notetitle content:nil notebookGuid:notebookGuid tagGuids:tagGuids completion:^(NSError *error) {
                        [self dismissActivityIndicators];
                        [self buttonEnable:button];
                        if (!error) {
                            [self menuNavigation:self.menuTagLast];
                            [self updateTableViews];
                            [self resetFields];
                        }
                    }];
                }
            }
            // notes (does not have category filter validation)
            else if (self.menuTagLast == 24) {
                NSLog(@"note edit");
                // pull
                NSString *noteGuid = [[(UILabel *)[self.cellPressed viewWithTag:85] text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                NSString *notetitle = [[(UITextField *)[self.cellPressed viewWithTag:83] text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];;
                // validate
                if (notetitle.length == 0) {
                    [Util showSimpleAlertWithMessage:@"Note must have a title"];
                    [self buttonEnable:button];
                } else if (notetitle.length > 249) {
                    [Util showSimpleAlertWithMessage:@"Note title cannot be longer than 250"];
                    [self buttonEnable:button];
                } else if ([self.noteFilters[@"notebookName"] count] == 0) {
                    [Util showSimpleAlertWithMessage:@"Note must have at least one notebook"];
                    [self buttonEnable:button];
                } else {
                    // update note
                    NSString *notebookGuid = [[Storage sharedInstance] getNotebookGuidWithName:[self.noteFilters[@"notebookName"] firstObject]];
                    NSMutableArray *tagGuids;
                    for (NSString *tagName in self.noteFilters[@"tagNames"]) {
                        (tagGuids == nil) ? tagGuids = [NSMutableArray array] : nil;
                        [tagGuids addObject:[[Storage sharedInstance] getTagGuidWithName:tagName]];
                    }
                    
                    [self showActivityIndicators];
                    [Evernote updateNote:noteGuid title:notetitle content:nil notebookGuid:notebookGuid tagGuids:tagGuids completion:^(NSError *error) {
                        [self dismissActivityIndicators];
                        [self buttonEnable:button];
                        if (!error) {
                            [self menuNavigation:self.menuTagLast];
                            [self updateTableViews];
                            [self resetFields];
                        }
                    }];
                }
            }
        }
        else if ([self menuCurrent] == self.menuNoteView) {
            NSLog(@"note view");
            // pull
            NSString *noteGuid = [[(UILabel *)[self.cellPressed viewWithTag:85] text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSString *notetitle = [[(UITextField *)[self.viewNoteView.view viewWithTag:91] text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            // validate
            if (notetitle.length == 0) {
                [Util showSimpleAlertWithMessage:@"Note must have a title"];
                [self buttonEnable:button];
            } else if (notetitle.length > 249) {
                [Util showSimpleAlertWithMessage:@"Note title cannot be longer than 250"];
                [self buttonEnable:button];
            } else if ([self.noteFilters[@"notebookName"] count] == 0) {
                [Util showSimpleAlertWithMessage:@"Note must have at least one notebook"];
                [self buttonEnable:button];
            } else {
                // get guids
                NSString *notebookGuid = [[Storage sharedInstance] getNotebookGuidWithName:[self.noteFilters[@"notebookName"] firstObject]];
                NSMutableArray *tagGuids;
                for (NSString *tagName in self.noteFilters[@"tagNames"]) {
                    (tagGuids == nil) ? tagGuids = [NSMutableArray array] : nil;
                    [tagGuids addObject:[[Storage sharedInstance] getTagGuidWithName:tagName]];
                }
                
                // update note
                [self showActivityIndicators];
                [Evernote updateNote:noteGuid title:notetitle content:[self.viewNoteView getNoteContent] notebookGuid:notebookGuid tagGuids:tagGuids completion:^(NSError *error) {
                    [self dismissActivityIndicators];
                    [self buttonEnable:button];
                    if (!error) {
                        [Util showSimpleAlertWithMessage:@"Successful note update" andButton:nil forSeconds:0.4];
                        [self menuNavigation:self.menuTagLast];
                        [self updateTableViews];
                        [self resetFields];
                    } else {
                        NSLog(@"error: %@",error);
                    }
                }];
            }
            
        }
    }
    // go back
    else {
        button.selected = !button.selected;
        [(UITextField *)[self.cellPressed viewWithTag:83] setText:self.cellNoteTitleLast];
        [self menuNavigation:self.menuTagLast];
        [self resetFields];
    }
}

-(void)menuCancel:(UIButton *)button {
    button.selected = !button.selected;
    // stop download
    if ([[UIApplication sharedApplication] isNetworkActivityIndicatorVisible]) {
        // TODO:
        // stop evernote pull
        // reset the refresh buttons
        [self dismissActivityIndicators];
    }
    // or search searchtext and redownload
    else {
        // reset searchtext
        UITextField *textField;
        if ([self menuCurrent] == self.menuTasks) {
            textField = (UITextField *)[[self.menuTasks.view viewWithTag:4] viewWithTag:32];
            [self.tasksFilters setObject:[NSString string] forKey:@"searchText"];
            [self.tasksFilters setObject:[NSMutableArray array] forKey:@"searchNoteGuids"];
        } else if ([self menuCurrent] == self.menuNotes) {
            textField = (UITextField *)[[self.menuNotes.view viewWithTag:2] viewWithTag:32];
            [self.notesFilters setObject:[NSString string] forKey:@"searchText"];
            [self.notesFilters setObject:[NSMutableArray array] forKey:@"searchNoteGuids"];
        }
        
        [textField setText:@""];
        textField.layer.borderColor = [[Config sharedInstance].colorOutline CGColor];
        [textField resignFirstResponder];
        
        [self updateTableViews];
    }
}

-(void)menuCell:(UIButton *)button {
    // pull info
    NSString *noteGuid = [(UILabel *)[[button superview] viewWithTag:85] text];
    NSString *noteTitle = [(UITextField *)[[button superview] viewWithTag:83] text];
    UIWebView *webViewContent = (UIWebView *)[self.viewNoteView.view viewWithTag:92];
    
    // download contents (called webview delegate)
    [self showActivityIndicators];
    [Evernote getNoteContents:noteGuid completion:^(NSString *noteContent) {
        [self dismissActivityIndicators];
        if (noteContent != nil) {
            // pass to webview delegate
            self.cellNoteContents = noteContent;
            
            // TODO: move to menuNavigation
            [self menuHide];
            
            // store property for update note submit
            self.cellNoteTitleLast = noteTitle;
            self.cellPressed = [button superview];
            
            // TODO: RECYCLED CODE FROM UPDATE NOTEVIEW (NEED COMBINE)
            /////////////////
            
            // fill menu
            NSDictionary *note = [[[Storage sharedInstance] getNotesWithNoteGuids:@[noteGuid] notebookGuids:nil tagGuids:nil sortType:SortTypeAZ] firstObject];
            NSMutableArray *tags = note[@"noteTagNames"];
            NSString *notebook = note[@"noteNotebookName"];
            UIView *row;
            // tags
            for (NSInteger i = 1 ; i <= 3; i++) {
                row = [self.menuNoteView.view viewWithTag:i];
                for (UIButton *filter in [row subviews]) {
                    if (![filter isKindOfClass:[UIImageView class]]) {
                        NSInteger index = [tags indexOfObject:filter.titleLabel.text];
                        if (index != NSNotFound) {
                            [filter setSelected:YES];
                            [filter.layer setBorderColor:[[Config sharedInstance].colorSelected CGColor]];
                            [self.noteFilters[@"tagNames"] addObject:filter.titleLabel.text];
                        }
                    }
                }
            }
            // notebook
            row = [self.menuNoteView.view viewWithTag:4];
            for (UIButton *filter in [row subviews]) {
                if (![filter isKindOfClass:[UIImageView class]]) {
                    if (notebook == filter.titleLabel.text) {
                        [filter setSelected:YES];
                        [filter.layer setBorderColor:[[Config sharedInstance].colorOutline CGColor]];
                        [self.noteFilters[@"notebookName"] addObject:filter.titleLabel.text];
                    }
                }
            }
            
            /////////////////
            
            // fill view
            [(UITextField *)[self.viewNoteView.view viewWithTag:91] setText:noteTitle];
            NSURL *htmlFile = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"ckeditor/template" ofType:@"html"] isDirectory:NO];
            [webViewContent loadRequest:[NSURLRequest requestWithURL:htmlFile]];
            
            // show view
            [self.menuNoteView.view setHidden:NO];
            [self.viewNoteView.view setHidden:NO];
        } else {
            
        }
    }];
}

-(void)menuResize {
    NSLog(@"redraw");
    // resize all main containers because of changes in the status bar's height ( other app notifications)
    float diff = self.view.frame.size.height - [Config sharedInstance].frameHeight;
    [Config sharedInstance].frameHeight = self.view.frame.size.height;
    
    CGRect rectContent;
    CGRect rectMenu;
    
    // load
    rectContent = self.viewLoad.view.frame;
    rectContent.size.height += diff;
    self.viewLoad.view.frame = rectContent;
    [self.viewLoad.view setNeedsLayout];
    
    rectMenu = self.menuLoad.view.frame;
    rectMenu.origin.y += diff;
    self.menuLoad.view.frame = rectMenu;
    [self.menuLoad.view setNeedsLayout];
    
    // settings
    rectContent = self.viewSettings.view.frame;
    rectContent.size.height += diff;
    self.viewSettings.view.frame = rectContent;
    
    rectMenu = self.menuSettings.view.frame;
    rectMenu.origin.y += diff;
    self.menuSettings.view.frame = rectMenu;
    
    // tasks
    rectContent = self.tableViewTasks.tableView.frame;
    rectContent.size.height += diff;
    self.tableViewTasks.tableView.frame = rectContent;
    
    rectMenu = self.menuTasks.view.frame;
    rectMenu.origin.y += diff;
    self.menuTasks.view.frame = rectMenu;
    
    // goals
    rectContent = self.viewGoals.view.frame;
    rectContent.size.height += diff;
    self.viewGoals.view.frame = rectContent;
    
    rectMenu = self.menuGoals.view.frame;
    rectMenu.origin.y += diff;
    self.menuGoals.view.frame = rectMenu;
    
    // notes
    rectContent = self.tableViewNotes.tableView.frame;
    rectContent.size.height += diff;
    self.tableViewNotes.tableView.frame = rectContent;
    
    rectMenu = self.menuNotes.view.frame;
    rectMenu.origin.y += diff;
    self.menuNotes.view.frame = rectMenu;
    
    // taskcreate
    UITextView *taskContent = (UITextView *)[self.viewTaskCreate.view viewWithTag:72];
    rectContent = taskContent.frame;
    rectContent.size.height += diff;
    taskContent.frame = rectContent;
    
    // notecreate
    UITextView *noteContent = (UITextView *)[self.viewNoteCreate.view viewWithTag:72];
    rectContent = noteContent.frame;
    rectContent.size.height += diff;
    noteContent.frame = rectContent;
    
    // notecontent
    rectContent = self.viewNoteView.view.frame;
    rectContent.size.height += diff;
    self.viewNoteView.view.frame = rectContent;
    
    rectMenu = self.menuNoteView.view.frame;
    rectMenu.origin.y += diff;
    self.menuNoteView.view.frame = rectMenu;
    
}

#pragma mark - filter selection
-(void)filterTap:(UIButton *)button {
    NSLog(@"filter tap");
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // determine which array (reference it)
        NSMutableDictionary *searchDictionary;
        if ([[self menuCurrent] isEqual:self.menuTasks]) {
            [self showActivityIndicators];
            searchDictionary = self.tasksFilters;
        } else if ([[self menuCurrent] isEqual:self.menuNotes]) {
            [self showActivityIndicators];
            searchDictionary = self.notesFilters;
        } else {
            searchDictionary = self.noteFilters;
        }
        
        // determine if notebook or tag
        NSString *searchKey;
        NSMutableArray *searchKeyArray = [NSMutableArray array];
        if (button.tag == 51 || button.tag == 52) {
            searchKey = @"tagNames";
        } else if (button.tag == 53) {
            searchKey = @"notebookName";
        }
        searchKeyArray = [searchDictionary objectForKey:searchKey];
        
        if (button.isSelected) {
            // add it array
            [searchKeyArray addObject:button.titleLabel.text];
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [button setSelected:YES];
                [button.layer setBorderColor:[[Config sharedInstance].colorSelected CGColor]];
            });
        } else {
            // remove it from array (user toggled the button)
            // while b/c duplication possible with multi select
            while ([searchKeyArray indexOfObject:button.titleLabel.text] != NSNotFound) {
                [searchKeyArray removeObjectAtIndex:[searchKeyArray indexOfObject:button.titleLabel.text]];
            }
        }
        
        // if single selection
        if (button.tag != 52) {
            // go through all filters on this level
            for (UIButton *filter in [[[self menuCurrent].view viewWithTag:[button superview].tag] subviews]) {
                // input accessory views randomly create UIImageView for some reason
                if (![filter isKindOfClass:[UIImageView class]]) {
                    if (![filter.titleLabel.text isEqualToString:button.titleLabel.text]) {
                        // deselect
                        dispatch_async(dispatch_get_main_queue(), ^(void){
                            [filter setSelected:NO];
                            [filter.layer setBorderColor:[[Config sharedInstance].colorOutline CGColor]];
                        });
                        // remove from array
                        if ([searchKeyArray indexOfObject:filter.titleLabel.text] != NSNotFound) {
                            [searchKeyArray removeObjectAtIndex:[searchKeyArray indexOfObject:filter.titleLabel.text]];
                        }
                    }
                }
            }
        }
        
        // update the filter array
        [searchDictionary setObject:searchKeyArray forKey:searchKey];
        
        // update the views
        if (searchDictionary != self.noteFilters) {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [self updateTableViews];
            });
        }
    });
}

-(void)sort:(UIButton *)button {
    // reset the button select
    button.selected = !button.selected;
    
    // sort type
    SortType sortType = SortTypeAZ;;
    
    // change the icon and set descriptor values
    if ([button.titleLabel.text isEqualToString:@"Sort-az"]) {
        [button setImage:[UIImage imageNamed:@"sortzanormal"] forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:@"sortzaselected"] forState:UIControlStateHighlighted];
        [button setTitle:@"Sort-za" forState:UIControlStateNormal];
        sortType = SortTypeZA;
    } else if ([button.titleLabel.text isEqualToString:@"Sort-za"]) {
        [button setImage:[UIImage imageNamed:@"sort19normal"] forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:@"sort19selected"] forState:UIControlStateHighlighted];
        [button setTitle:@"Sort-19" forState:UIControlStateNormal];
        sortType = SortType19;
    } else if ([button.titleLabel.text isEqualToString:@"Sort-19"]) {
        [button setImage:[UIImage imageNamed:@"sort91normal"] forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:@"sort91selected"] forState:UIControlStateHighlighted];
        [button setTitle:@"Sort-91" forState:UIControlStateNormal];
        sortType = SortType91;
    } else if ([button.titleLabel.text isEqualToString:@"Sort-91"]) {
        [button setImage:[UIImage imageNamed:@"sortaznormal"] forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:@"sortazselected"] forState:UIControlStateHighlighted];
        [button setTitle:@"Sort-az" forState:UIControlStateNormal];
        sortType = SortTypeAZ;
    }
    
    // create the descriptor
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // update the properties
        if ([[self menuCurrent] isEqual:self.menuTasks]) {
            self.tasksSort = sortType;
        } else if ([[self menuCurrent] isEqual:self.menuNotes]) {
            self.notesSort = sortType;
        }
        
        // reload the tableview
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateTableViews];
        });
    });
}

-(void) refreshFields {
    // reset menus
    [self.menuTasks updateRow:1 withFilters:self.filterWhere withSelectionType:SelectionTypeTagSingle withController:self];
    [self.menuTasks updateRow:2 withFilters:self.filterWhen withSelectionType:SelectionTypeTagSingle withController:self];
    [self.menuTasks updateRow:3 withFilters:self.filterWhat withSelectionType:SelectionTypeTagMultiple withController:self];
    
    [self.menuNotes updateRow:1 withFilters:self.filterNotesbook withSelectionType:SelectionTypeNotebookSingle withController:self];
    
    [self.menuTaskCreate updateRow:1 withFilters:self.filterWhere withSelectionType:SelectionTypeTagSingle withController:self];
    [self.menuTaskCreate updateRow:2 withFilters:self.filterWhen withSelectionType:SelectionTypeTagSingle withController:self];
    [self.menuTaskCreate updateRow:3 withFilters:self.filterWhat withSelectionType:SelectionTypeTagMultiple withController:self];
    
    [self.menuNoteCreate updateRow:1 withFilters:self.filterNotesbook withSelectionType:SelectionTypeNotebookSingle withController:self];
    
    [self.menuNoteEdit updateRow:1 withFilters:self.filterWhere withSelectionType:SelectionTypeTagSingle withController:self];
    [self.menuNoteEdit updateRow:2 withFilters:self.filterWhen withSelectionType:SelectionTypeTagSingle withController:self];
    [self.menuNoteEdit updateRow:3 withFilters:self.filterWhat withSelectionType:SelectionTypeTagMultiple withController:self];
    [self.menuNoteEdit updateRow:4 withFilters:self.filterNotesbook withSelectionType:SelectionTypeNotebookSingle withController:self];
    
    [self.menuNoteView updateRow:1 withFilters:self.filterWhere withSelectionType:SelectionTypeTagSingle withController:self];
    [self.menuNoteView updateRow:2 withFilters:self.filterWhen withSelectionType:SelectionTypeTagSingle withController:self];
    [self.menuNoteView updateRow:3 withFilters:self.filterWhat withSelectionType:SelectionTypeTagMultiple withController:self];
    [self.menuNoteView updateRow:4 withFilters:self.filterNotesbook withSelectionType:SelectionTypeNotebookSingle withController:self];
    
    // reselect filters
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // tasks
        for (int i = 1; i <= 3 ; i++) {
            for (UIButton *filter in [[self.menuTasks.view viewWithTag:i] subviews]) {
                if (![filter isKindOfClass:[UIImageView class]]) {
                    if ([self.tasksFilters[@"tagNames"] count] > 0) {
                        if ([self.tasksFilters[@"tagNames"] indexOfObject:filter.titleLabel.text] != NSNotFound) {
                            dispatch_async(dispatch_get_main_queue(), ^(void){
                                [filter setSelected:YES];
                                [filter.layer setBorderColor:[[Config sharedInstance].colorSelected CGColor]];
                            });
                        }
                    }
                }
            }
        }
        
        // notes
        for (UIButton *filter in [[self.menuNotes.view viewWithTag:1] subviews]) {
            if (![filter isKindOfClass:[UIImageView class]]) {
                if ([self.notesFilters[@"notebookName"] count] > 0) {
                    if ([self.notesFilters[@"notebookName"] indexOfObject:filter.titleLabel.text] != NSNotFound) {
                        dispatch_async(dispatch_get_main_queue(), ^(void){
                            dispatch_async(dispatch_get_main_queue(), ^(void){
                                [filter setSelected:YES];
                                [filter.layer setBorderColor:[[Config sharedInstance].colorSelected CGColor]];
                            });
                        });
                    }
                }
            }
        }
    });
}

#pragma mark - textfields
-(void)resetFields {
    // for create and view note
    NSLog(@"reset fields");
    
    // create note textfields
    [(UITextField *)[self.viewTaskCreate.view viewWithTag:71] setText:@""];
    [(UITextView *)[self.viewTaskCreate.view viewWithTag:72] setText:@""];
    [(UITextField *)[self.viewNoteCreate.view viewWithTag:71] setText:@""];
    [(UITextView *)[self.viewNoteCreate.view viewWithTag:72] setText:@""];
    [(UITextField *)[self.viewNoteView.view viewWithTag:91] setText:@""];
    [(UIWebView *)[self.viewNoteView.view viewWithTag:92] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
    
    // view note array
    self.noteFilters = [NSMutableDictionary dictionaryWithObjects:@[[NSMutableArray array], [NSMutableArray array], [NSMutableArray array]] forKeys:@[@"searchText", @"tagNames", @"notebookName"]];
    
    // view note and create note filters and scrollviews
    [(UIScrollView *)[self.menuNoteCreate.view viewWithTag:1] setContentOffset:CGPointMake(0,0) animated:YES];
    for (UIButton *filter in [[self.menuNoteCreate.view viewWithTag:1] subviews]) {
        if (![filter isKindOfClass:[UIImageView class]]) {
            [filter setSelected:NO];
            [filter.layer setBorderColor:[[Config sharedInstance].colorOutline CGColor]];
        }
    }
    for (int i = 1; i <= 3; i++) {
        [(UIScrollView *)[self.menuTaskCreate.view viewWithTag:i] setContentOffset:CGPointMake(0,0) animated:YES];
        for (UIButton *filter in [[self.menuTaskCreate.view viewWithTag:i] subviews]) {
            if (![filter isKindOfClass:[UIImageView class]]) {
                [filter setSelected:NO];
                [filter.layer setBorderColor:[[Config sharedInstance].colorOutline CGColor]];
            }
        }
    }
    for (int i = 1; i <= 4; i++) {
        [(UIScrollView *)[self.menuNoteEdit.view viewWithTag:i] setContentOffset:CGPointMake(0,0) animated:YES];
        for (UIButton *filter in [[self.menuNoteEdit.view viewWithTag:i] subviews]) {
            if (![filter isKindOfClass:[UIImageView class]]) {
                [filter setSelected:NO];
                [filter.layer setBorderColor:[[Config sharedInstance].colorOutline CGColor]];
            }
        }
    }
    for (int i = 1; i <= 4; i++) {
        [(UIScrollView *)[self.menuNoteView.view viewWithTag:i] setContentOffset:CGPointMake(0,0) animated:YES];
        for (UIButton *filter in [[self.menuNoteView.view viewWithTag:i] subviews]) {
            if (![filter isKindOfClass:[UIImageView class]]) {
                [filter setSelected:NO];
                [filter.layer setBorderColor:[[Config sharedInstance].colorOutline CGColor]];
            }
        }
    }
    
    // kill keybaord
    [self dismissKeyboard];
}

-(void)textFieldDidBeginEditing:(UITextField *)textField {
    NSLog(@"textfield did begin editing %li", (long)textField.tag);
    
    // search text in menu
    if (textField.tag == 32) {
        self.tasksSearchTextfieldOverride = false;
        self.notesSearchTextfieldOverride = false;
        
        // set override (to select the input)
        if ([self menuCurrent] == self.menuTasks) {
            self.tasksSearchTextfieldOverride = true;
        } else if ([self menuCurrent] == self.menuNotes) {
            self.notesSearchTextfieldOverride = true;
        }
        [self.menuNoteSearch.view setHidden:NO];
    }
    
    // note title edit
    if (textField.tag == 83) {
        self.cellNoteTitleLast = textField.text;
        [self updateNoteEdit:textField];
    }
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
    NSLog(@"textfield did end editing");
    
    // note title or search text
    if (textField.tag == 83 || textField.tag == 38) {
        CGRect rectContent;
        if (self.menuTagLast == 22) {
            rectContent = self.tableViewTasks.tableView.frame;
            rectContent.size.height = [Config sharedInstance].frameHeight - self.menuTasks.view.frame.size.height - [Config sharedInstance].statusBarHeight;
            self.tableViewTasks.tableView.frame = rectContent;
        } else if (self.menuTagLast == 24) {
            rectContent = self.tableViewNotes.tableView.frame;
            rectContent.size.height = [Config sharedInstance].frameHeight - self.menuNotes.view.frame.size.height - [Config sharedInstance].statusBarHeight;
            self.tableViewNotes.tableView.frame = rectContent;
        }
        [self.menuNoteEdit.view setHidden:YES];
        [self resetFields];
    }
}

-(void)textViewDidEndEditing:(UITextView *)textView {
    
    // resize goals textview
    CGRect contentFrame;
    UITextView *noteContent = (UITextView *)[self.viewGoals.view viewWithTag:72];
    contentFrame = noteContent.frame;
    contentFrame.size.height = [[Config sharedInstance] frameHeight] - [[Config sharedInstance] statusBarHeight] - self.menuGoals.view.frame.size.height - 40;
    noteContent.frame = contentFrame;
}


-(void)textFieldDidChange:(UITextField *)textField {
    NSLog(@"textfield did change");
    
    // search textfield
    [self textFieldSetBorderColor:textField];
}

-(void)textFieldSetBorderColor:(UITextField *)textField {
    if ([textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length > 0)  {
        textField.layer.borderColor = [[Config sharedInstance].colorSelected CGColor];
    } else {
        textField.layer.borderColor = [[Config sharedInstance].colorOutline CGColor];
    }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSLog(@"textfield should return %ld", (long)textField.tag);
    
    // new note - switch from title to content
    if (textField.tag == 71) {
        NSInteger nextTag = textField.tag + 1;
        UIResponder *nextResponder = [textField.superview viewWithTag:nextTag];
        [nextResponder becomeFirstResponder];
    }
    
    // note title edit
    if (textField.tag == 83) {
        [self menuConfirm:(UIButton *)[[self.menuNoteEdit.view viewWithTag:5] viewWithTag:63]];
    }
    
    // search input
    if (textField.tag == 38) {
        [self evernoteSearch:(UIButton *)[[self.menuNoteSearch.view viewWithTag:1] viewWithTag:40]];
    }
    
    // view title
    if (textField.tag == 91) {
        [self dismissKeyboard];
    }
    
    return NO;
}

#pragma mark - keyboard
-(void)keyboardWillShow:(NSNotification *)notification {
    NSLog(@"keyboard will show");
    
    // grab keyboard height
    float diff = [[[notification userInfo] valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height - [Config sharedInstance].keyboardHeight;
    
    // if different, resize views
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, .2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
        // delay to make sure the view does not change sizes before the keybaord is completely extended
        CGRect contentFrame;
        if (diff != 0) {
            [Config sharedInstance].keyboardHeight += diff;
            if ([self menuCurrent] == self.menuTaskCreate) {
                // create task
                UITextView *taskContent = (UITextView *)[self.viewTaskCreate.view viewWithTag:72];
                contentFrame = taskContent.frame;
                contentFrame.size.height -= diff;
                taskContent.frame = contentFrame;
            } else if ([self menuCurrent] == self.menuNoteCreate) {
                // create note
                UITextView *noteContent = (UITextView *)[self.viewNoteCreate.view viewWithTag:72];
                contentFrame = noteContent.frame;
                contentFrame.size.height -= diff;
                noteContent.frame = contentFrame;
            } else if ([self menuCurrent] == self.menuNoteEdit && [self.menuNoteView.view isHidden]) {
                if (self.menuTagLast == 22) {
                    contentFrame = self.tableViewTasks.tableView.frame;
                    contentFrame.size.height = abs(diff - self.tableViewTasks.tableView.frame.size.height);
                    self.tableViewTasks.tableView.frame = contentFrame;
                } else if (self.menuTagLast == 24) {
                    contentFrame = self.tableViewNotes.tableView.frame;
                    contentFrame.size.height = abs(diff - self.tableViewNotes.tableView.frame.size.height);
                    self.tableViewNotes.tableView.frame = contentFrame;
                }
            }
        }
        
        if ([self menuCurrent] == self.menuTasks) {
            contentFrame = self.tableViewTasks.tableView.frame;
            contentFrame.size.height = [[Config sharedInstance] frameHeight] - [[Config sharedInstance] statusBarHeight] - [Config sharedInstance].keyboardHeight;
            self.tableViewTasks.tableView.frame = contentFrame;
        } else if ([self menuCurrent] == self.menuTasks) {
            contentFrame = self.tableViewNotes.tableView.frame;
            contentFrame.size.height = [[Config sharedInstance] frameHeight] - [[Config sharedInstance] statusBarHeight] - [Config sharedInstance].keyboardHeight;
            self.tableViewNotes.tableView.frame = contentFrame;
        } else if ([self menuCurrent] == self.menuGoals) {
            UITextView *noteContent = (UITextView *)[self.viewGoals.view viewWithTag:72];
            contentFrame = noteContent.frame;
            contentFrame.size.height = [[Config sharedInstance] frameHeight] - [[Config sharedInstance] statusBarHeight] - [Config sharedInstance].keyboardHeight - 40;
            noteContent.frame = contentFrame;
        }
    });
    
    // if searchtext pressed
    if (self.tasksSearchTextfieldOverride || self.notesSearchTextfieldOverride) {
        [(UITextField *)[[self.menuNoteSearch.view viewWithTag:1] viewWithTag: 38] becomeFirstResponder];
    }
    if (self.tasksSearchTextfieldOverride) {
        self.tasksSearchLast = [(UITextField *)[[self.menuTasks.view viewWithTag:4] viewWithTag: 32] text];
        [(UITextField *)[[self.menuNoteSearch.view viewWithTag:1] viewWithTag: 38] setText:self.tasksSearchLast];
        [(UILabel *)[[self.menuNoteSearch.view viewWithTag:1] viewWithTag: 33] setText:[(UILabel *)[self.menuTasks.view viewWithTag:33] text]];
    } else if (self.notesSearchTextfieldOverride) {
        self.notesSearchLast = [(UITextField *)[[self.menuNotes.view viewWithTag:2] viewWithTag: 32] text];
        [(UITextField *)[[self.menuNoteSearch.view viewWithTag:1] viewWithTag: 38] setText:self.notesSearchLast];
        [(UILabel *)[[self.menuNoteSearch.view viewWithTag:1] viewWithTag: 33] setText:[(UILabel *)[self.menuNotes.view viewWithTag:33] text]];
    }
}

-(void)dismissKeyboard {
    [self.view endEditing:YES];
}

#pragma mark - webview
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSLog(@"webview did finish load");
    // fill
    webView.opaque = NO;
    [webView setBackgroundColor:[Config sharedInstance].colorSelected];
    
    // need to extract the header first (first <en-note>)
    NSString *fileContent = self.cellNoteContents;
    [fileContent UTF8String];
    fileContent = [[[[[fileContent stringByReplacingOccurrencesOfString:@"\"" withString:@"&#34"]
                      stringByReplacingOccurrencesOfString:@"'" withString:@"&#39;"]
                     stringByReplacingOccurrencesOfString:@"\\" withString:@"&#92;"]
                    componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@""];
    
    NSString *str = [NSString stringWithFormat:@"document.getElementById('editor1').innerHTML='%@';",fileContent];
    
    [webView stringByEvaluatingJavaScriptFromString:str];
    [webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('editor1').focus();"];
}

#pragma mark - frame
-(void)showActivityIndicators {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            if ([self menuCurrent] == self.menuNoteView) {
                [SVProgressHUD setForegroundColor:[Config sharedInstance].colorSelected];
            } else {
                [SVProgressHUD setForegroundColor:[Config sharedInstance].colorBackground];
            }
            [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeNone];
        });
    });
}

-(void)dismissActivityIndicators {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            [SVProgressHUD dismiss];
        });
    });
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    UIButton *button;
    if ([self menuCurrent] == self.menuTasks) {
        button = (UIButton *)[[self.menuTasks.view viewWithTag:4] viewWithTag:35];
    } else if ([self menuCurrent] == self.menuNotes) {
        button = (UIButton *)[[self.menuNotes.view viewWithTag:2] viewWithTag:35];
    }
    
    // if TRASH pressed Yes to delete all completed notes
    if (buttonIndex == 1) {
        [self showActivityIndicators];
        NSArray *completedNotes = [[Storage sharedInstance] getNotesWithNoteGuids:nil notebookGuids:@[[[Storage sharedInstance] getNotebookGuidWithName:@"Completed"]] tagGuids:nil sortType:SortTypeZA];
        
        __block NSInteger noteDeleted = 0;
        if (completedNotes.count > 0) {
            for (NSDictionary *note in completedNotes) {
                __block BOOL failure = false;
                [Evernote deleteNote:note[@"noteGuid"] completion:^(NSError *error) {
                    if (!error) {
                        noteDeleted++;
                    } else {
                        failure = true;
                    }
                    
                    if (noteDeleted == completedNotes.count) {
                        [self updateTableViews];
                        [Util showSimpleAlertWithMessage:[NSString stringWithFormat:@"Successfully deleted %ld notes",(long)noteDeleted] andButton:nil forSeconds:0.7f];
                        [self buttonEnable:button];
                    }
                }];
                if (failure) {
                    [self buttonEnable:button];
                    [self updateTableViews];
                    break;
                }
            }
        } else {
            [self buttonEnable:button];
        }
    } else {
        [self buttonEnable:button];
    }
}

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

@end

