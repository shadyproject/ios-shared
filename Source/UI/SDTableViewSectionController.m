//
//  SDTableViewSectionController.m
//  ios-shared

//
//  Created by Steve Riggins & Woolie on 1/2/14.
//  Copyright (c) 2014 SetDirection. All rights reserved.
//

#import "SDTableViewSectionController.h"

@interface SDTableViewSectionController () <UITableViewDataSource, UITableViewDelegate>
{
    // Private flags
    BOOL _sectionsImplementHeightForRow;
    BOOL _sectionsImplementTitleForHeader;
    BOOL _sectionsImplementViewForHeader;
    BOOL _sectionsImplementHeightForHeader;
    BOOL _sectionsImplementEditingStyleForRow;
    BOOL _sectionsImplementCommitEditingStyleForRow;
    BOOL _sectionsImplementWillDisplayCellForRow;
    BOOL _sectionsImplementDidEndDisplayingCellForRow;
}

@property (nonatomic, weak)   UITableView *tableView;
@property (nonatomic, strong) NSArray     *sectionControllers;
@end

@implementation SDTableViewSectionController

- (instancetype)initWithTableView:(UITableView *)tableView
{
    self = [super init];
    if (self)
    {
        _tableView = tableView;
        tableView.delegate = self;
        tableView.dataSource = self;
    }
    
    return self;
}

- (void)reloadWithSectionControllers:(NSArray *)sectionControllers animated:(BOOL)animated
{
    @strongify(self.tableView, strongTableView);
    
    [self p_sendSectionDidUnload:self.sectionControllers];

    self.sectionControllers = sectionControllers;
    
    [self p_sendSectionDidLoad:self.sectionControllers];
    
      // Force caching of our flags and the table view's flags
    [self p_updateFlags];
    strongTableView.delegate = nil;
    strongTableView.dataSource = nil;
    strongTableView.delegate = self;
    strongTableView.dataSource = self;
    
    if (animated)
    {
        // Placeholder for future animated work
        // Currently allows for people to call reload without a tableView reloadData, but can still get the flags updated
    }
    else
    {
        [strongTableView reloadData];
    }
}

#pragma mark - UITableView DataSource

// This is where we hook to ask our dataSource for the Array of controllers
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger sectionCount;
    
    sectionCount = (NSInteger)self.sectionControllers.count;
    
    return sectionCount;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    id<SDTableViewSectionDelegate>sectionController = self.sectionControllers[(NSUInteger)section];
    if ([sectionController respondsToSelector:@selector(sectionController:commitEditingStyle:forRow:)])
    {
        [sectionController sectionController:self commitEditingStyle:editingStyle forRow:row];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    id<SDTableViewSectionDelegate>sectionController = self.sectionControllers[(NSUInteger)section];
    NSString *title;
    if ([sectionController respondsToSelector:@selector(sectionControllerTitleForHeader:)])
    {
        title = [sectionController sectionControllerTitleForHeader:self];
    }
    
    return title;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;
    
    id<SDTableViewSectionDelegate>sectionController = self.sectionControllers[(NSUInteger)section];
    if ([sectionController respondsToSelector:@selector(numberOfRowsForSectionController:)])
    {
        numberOfRows = [sectionController numberOfRowsForSectionController:self];
    }
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger section = (NSUInteger)indexPath.section;
    NSInteger row = indexPath.row;
    UITableViewCell *cell = nil;
    
    id<SDTableViewSectionDelegate>sectionController = self.sectionControllers[section];
    if ([sectionController respondsToSelector:@selector(sectionController:cellForRow:)])
    {
        cell = [sectionController sectionController:self cellForRow:row];
    }
    return cell;
}

#pragma mark - UITableView Delegate

#pragma mark Managing Selections

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    id<SDTableViewSectionDelegate>sectionController = self.sectionControllers[(NSUInteger)section];
    if ([sectionController respondsToSelector:@selector(sectionController:didSelectRow:)])
    {
        [sectionController sectionController:self didSelectRow:row];
    }
}


#pragma mark Configuring Rows for the Table View

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    id<SDTableViewSectionDelegate>sectionController = self.sectionControllers[(NSUInteger)section];
    CGFloat rowHeight = 44.0;
    if ([sectionController respondsToSelector:@selector(sectionController:heightForRow:)])
    {
        rowHeight = [sectionController sectionController:self heightForRow:row];
    }
    return rowHeight;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    id<SDTableViewSectionDelegate>sectionController = self.sectionControllers[(NSUInteger)section];
    if ([sectionController respondsToSelector:@selector(sectionController:willDisplayCell:forRow:)])
    {
        [sectionController sectionController:self willDisplayCell:cell forRow:row];
    }
}

#pragma mark Modifying the Header and Footer of Sections

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat headerHeight = 0.0;
    id<SDTableViewSectionDelegate>sectionController = self.sectionControllers[(NSUInteger)section];
    if ([sectionController respondsToSelector:@selector(sectionControllerHeightForHeader:)])
    {
        headerHeight =[sectionController sectionControllerHeightForHeader:self];
    }
    return headerHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *result = nil;
    id<SDTableViewSectionDelegate>sectionController = self.sectionControllers[(NSUInteger)section];
    if ([sectionController respondsToSelector:@selector(sectionControllerViewForHeader:)])
    {
        result = [sectionController sectionControllerViewForHeader:self];
    }
    return result;
}


#pragma mark Editing Table Rows

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCellEditingStyle editingStyle = UITableViewCellEditingStyleNone;
 
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    id<SDTableViewSectionDelegate>sectionController = self.sectionControllers[(NSUInteger)section];
    if ([sectionController respondsToSelector:@selector(sectionController:editingStyleForRow:)])
    {
        editingStyle =[sectionController sectionController:self editingStyleForRow:row];
    }
   
    return editingStyle;
}

#pragma mark Tracking the Removal of Views

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    id<SDTableViewSectionDelegate>sectionController = self.sectionControllers[(NSUInteger)section];
    if ([sectionController respondsToSelector:@selector(sectionController:didEndDisplayingCell:forRow:)])
    {
        [sectionController sectionController:self didEndDisplayingCell:cell forRow:row];
    }

}

#pragma mark - SectionController Methods

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    @strongify(self.delegate, delegate);
    if ([delegate conformsToProtocol:@protocol(SDTableViewSectionControllerDelegate)])
    {
        [delegate sectionController:self pushViewController:viewController animated:animated];
    }
}

- (void)presentViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(void))completion
{
    @strongify(self.delegate, delegate);
    if ([delegate respondsToSelector:@selector(sectionController:presentViewController:animated:completion:)])
    {
        [delegate sectionController:self presentViewController:viewController animated:animated completion:completion];
    }
}

- (void)dismissViewControllerAnimated: (BOOL)animated completion: (void (^)(void))completion
{
    @strongify(self.delegate, delegate);
    if ([delegate respondsToSelector:@selector(sectionController:dismissViewControllerAnimated:completion:)])
    {
        [delegate sectionController:self dismissViewControllerAnimated:animated completion:completion];
    }
}

- (void)popViewControllerAnimated:(BOOL)animated
{
    @strongify(self.delegate, delegate);
    if ([delegate respondsToSelector:@selector(sectionController:popViewController:)])
    {
        [delegate sectionController:self popViewController:animated];
    }   
}

- (void)popToRootViewControllerAnimated:(BOOL)animated
{
    @strongify(self.delegate, delegate);
    if ([delegate respondsToSelector:@selector(sectionController:popToRootViewControllerAnimated:)])
    {
        [delegate sectionController:self popToRootViewControllerAnimated:animated];
    }
}

- (NSUInteger)indexOfSection:(id<SDTableViewSectionDelegate>)section
{
    NSUInteger sectionIndex = [self.sectionControllers indexOfObject:section];
    return sectionIndex;
}

- (id<SDTableViewSectionDelegate>)sectionWithIdentifier:(NSString *)identifier
{
    id<SDTableViewSectionDelegate>section = nil;
    
    NSUInteger indexOfSection = [self.sectionControllers indexOfObjectPassingTest:^BOOL(id<SDTableViewSectionDelegate> obj, NSUInteger idx, BOOL *stop) {
        BOOL sectionAlreadyInArray = [obj.identifier isEqualToString: identifier];
        *stop = sectionAlreadyInArray;
        return sectionAlreadyInArray;
    }];
    
    if (indexOfSection != NSNotFound)
    {
        section = [self.sectionControllers objectAtIndex:indexOfSection];
    }
    
    return section;
}

#pragma mark - Height Methods

- (CGFloat)heightAboveSection:(id<SDTableViewSectionDelegate>)section maxHeight:(CGFloat)maxHeight
{
    CGFloat height = 0;
    NSUInteger sectionIndex = [self indexOfSection:section];
    if (sectionIndex > 0 && sectionIndex != NSNotFound)
    {
        NSRange rangeOfIndexes = NSMakeRange(0, sectionIndex);
        NSIndexSet *sectionIndexes = [[NSIndexSet alloc] initWithIndexesInRange:rangeOfIndexes];
        NSArray *sections = [self.sectionControllers objectsAtIndexes:sectionIndexes];
        height = [self p_heightForSections:sections maxHeight:maxHeight];
    }
    return height;
}

- (CGFloat)heightBelowSection:(id<SDTableViewSectionDelegate>)section maxHeight:(CGFloat)maxHeight
{
    CGFloat height = 0;
    NSUInteger sectionIndex = [self indexOfSection:section];
    if ((sectionIndex < (self.sectionControllers.count - 1) && sectionIndex != NSNotFound))
    {
        NSRange rangeOfIndexes = NSMakeRange(sectionIndex + 1, self.sectionControllers.count - sectionIndex - 1);
        NSIndexSet *sectionIndexes = [[NSIndexSet alloc] initWithIndexesInRange:rangeOfIndexes];
        NSArray *sections = [self.sectionControllers objectsAtIndexes:sectionIndexes];
        height = [self p_heightForSections:sections maxHeight:maxHeight];
    }
    return height;
}

- (CGFloat)p_heightForSection:(id<SDTableViewSectionDelegate>)section maxHeight:(CGFloat)maxHeight
{
    CGFloat sectionHeight = 0;

    @strongify(self.tableView, strongTableView);
    // Must check selector because section height is optional
    if ([section respondsToSelector:@selector(sectionControllerHeightForHeader:)])
    {
        sectionHeight = [section sectionControllerHeightForHeader:self];
    }
    else
    {
        if ([section respondsToSelector:@selector(sectionControllerTitleForHeader:)] ||
            [section respondsToSelector:@selector(sectionControllerViewForHeader:)])
        {
            sectionHeight = [strongTableView sectionHeaderHeight];
        }
    }
    
    // If we have not already exceeded maxHeight, let's look at the rows
    if (sectionHeight < maxHeight)
    {
        NSInteger numberOfCells = [section numberOfRowsForSectionController:self];
        for (NSInteger cellIndex = 0; cellIndex < numberOfCells; cellIndex++)
        {
            if ([section respondsToSelector:@selector(sectionController:heightForRow:)])
            {
                sectionHeight += [section sectionController:self heightForRow:cellIndex];
            }
            else
            {
                sectionHeight += [strongTableView rowHeight];
            }
            
            if (sectionHeight > maxHeight)
            {
                sectionHeight = maxHeight;
                break;
            }
        }
    }
    else
    {
        sectionHeight = maxHeight;
    }

    return sectionHeight;
}

- (CGFloat)p_heightForSections:(NSArray *)sections maxHeight:(CGFloat)maxHeight
{
    CGFloat height = 0;
    for (id<SDTableViewSectionDelegate>section in sections)
    {
        height += [self p_heightForSection:section maxHeight:maxHeight];
        if (height > maxHeight)
        {
            height = maxHeight;
            break;
        }
    }
    return height;
}

#pragma mark Private methods

// Based on the results of calling p_updateFlags, let table view know if we do or do not have
// sections that implement our proxy delegat methods
// This allows table view behavior to remain the same as if the we had never implemented those methods
- (BOOL)respondsToSelector:(SEL)aSelector
{
    BOOL result;
    if (aSelector == @selector(tableView:heightForRowAtIndexPath:))
    {
        result = _sectionsImplementHeightForRow;
    } else if (aSelector == @selector(tableView:titleForHeaderInSection:))
    {
        result = _sectionsImplementTitleForHeader;
    } else if (aSelector == @selector(tableView:viewForHeaderInSection:))
    {
        result = _sectionsImplementViewForHeader;
    } else if (aSelector == @selector(tableView:heightForHeaderInSection:))
    {
        result = _sectionsImplementHeightForHeader;
    } else if (aSelector == @selector(tableView:editingStyleForRowAtIndexPath:))
    {
        result = _sectionsImplementEditingStyleForRow;
    } else if (aSelector == @selector(tableView:commitEditingStyle:forRowAtIndexPath:))
    {
        result = _sectionsImplementCommitEditingStyleForRow;
    } else if (aSelector == @selector(tableView:willDisplayCell:forRowAtIndexPath:))
    {
        result = _sectionsImplementWillDisplayCellForRow;
    } else if (aSelector == @selector(tableView:didEndDisplayingCell:forRowAtIndexPath:))
    {
        result = _sectionsImplementDidEndDisplayingCellForRow;
    }
    else
    {
        result = [super respondsToSelector:aSelector];
    }
    return result;
}

// For every table view delegate/datasource method we proxy, keep a flag
// That we can use to lie to table view about whether we "implement" that
// API or not via respondsToSelector
- (void)p_updateFlags
{
    _sectionsImplementHeightForRow = NO;
    _sectionsImplementTitleForHeader = NO;
    _sectionsImplementViewForHeader = NO;
    _sectionsImplementHeightForHeader = NO;
    _sectionsImplementCommitEditingStyleForRow = NO;
    _sectionsImplementEditingStyleForRow = NO;
    _sectionsImplementWillDisplayCellForRow = NO;
    _sectionsImplementDidEndDisplayingCellForRow = NO;
    
    for (NSUInteger controllerIndex = 0; controllerIndex < self.sectionControllers.count; controllerIndex++)
    {
        id<SDTableViewSectionDelegate>sectionController = self.sectionControllers[controllerIndex];
        
        // OR (option) delegate methods
        // We need to handle this delegate if ANY of the sections implement these delegate methods
        _sectionsImplementTitleForHeader |= [sectionController respondsToSelector:@selector(sectionControllerTitleForHeader:)];
        _sectionsImplementViewForHeader |= [sectionController respondsToSelector:@selector(sectionControllerViewForHeader:)];
        _sectionsImplementHeightForHeader |= [sectionController respondsToSelector:@selector(sectionControllerHeightForHeader:)];
        _sectionsImplementEditingStyleForRow |= [sectionController respondsToSelector:@selector(sectionController:editingStyleForRow:)];
        _sectionsImplementCommitEditingStyleForRow |= [sectionController respondsToSelector:@selector(sectionController:commitEditingStyle:forRow:)];
        _sectionsImplementWillDisplayCellForRow |= [sectionController respondsToSelector:@selector(sectionController:willDisplayCell:forRow:)];
        _sectionsImplementDidEndDisplayingCellForRow |= [sectionController respondsToSelector:@selector(sectionController:didEndDisplayingCell:forRow:)];
        
        // AND delegate methods
        // If one of the sections implements these delegate methods, then all must
        BOOL sectionsImplementHeightForRow = [sectionController respondsToSelector:@selector(sectionController:heightForRow:)];
        if (controllerIndex == 0)
        {
            _sectionsImplementHeightForRow = sectionsImplementHeightForRow;
        }
        else
        {
            NSAssert(_sectionsImplementHeightForRow == sectionsImplementHeightForRow, @"If one section implements sectionController:heightForRow:, then all sections must");
        }
    }
}

- (void)addSection:(id<SDTableViewSectionDelegate>)section
{
    NSUInteger index = [self.sectionControllers count];
    
    // make sure we are not adding the same section twice
    id<SDTableViewSectionDelegate>sectionWithSameIdentifier;
    sectionWithSameIdentifier = [self sectionWithIdentifier:section.identifier];
    NSAssert(sectionWithSameIdentifier == nil, @"Adding section of identifier: %@ that already exists", section.identifier);
    
    // First change the model of section controllers
    NSMutableArray *newSectionControllers = [NSMutableArray arrayWithArray:self.sectionControllers];
    [newSectionControllers addObject:section];
    self.sectionControllers = [newSectionControllers copy];
    
    // Now add the section to the tableview
    @strongify(self.tableView, tableView);
    NSIndexSet *setOfSectionsToAdd = [[NSIndexSet alloc] initWithIndex:index];
    [tableView beginUpdates];
    [tableView insertSections:setOfSectionsToAdd withRowAnimation:UITableViewRowAnimationFade];
    [tableView endUpdates];
}

- (void)removeSection:(id<SDTableViewSectionDelegate>)section
{
    NSUInteger index = [self.sectionControllers indexOfObject:section];
    if (index > 0)
    {
        // First change the model of section controllers
        NSMutableArray *newSectionControllers = [NSMutableArray arrayWithArray:self.sectionControllers];
        [newSectionControllers removeObjectAtIndex:index];
        self.sectionControllers = [newSectionControllers copy];

        // Now nuke the section from the tableview
        @strongify(self.tableView, tableView);
        NSIndexSet *setOfSectionsToDelete = [[NSIndexSet alloc] initWithIndex:index];
        [tableView beginUpdates];
        [tableView deleteSections:setOfSectionsToDelete withRowAnimation:UITableViewRowAnimationFade];
        [tableView endUpdates];
     }
}

- (void)reloadSectionWithIdentifier:(NSString *)identifier withRowAnimation:(UITableViewRowAnimation)animation
{
    id<SDTableViewSectionDelegate> section = [self sectionWithIdentifier:identifier];
    if (section) {
        NSUInteger sectionIndex = [self indexOfSection:section];
        NSIndexSet *indexSet = [[NSIndexSet alloc] initWithIndex:sectionIndex];
        @strongify(self.tableView, tableView);
        [tableView beginUpdates];
        [tableView reloadSections:indexSet withRowAnimation:animation];
        [tableView endUpdates];
    }
}

- (void)p_sendSectionDidLoad:(NSArray *)sectionControllers
{
    for (id sectionController in sectionControllers)
    {
        if ([sectionController respondsToSelector:@selector(sectionDidLoad)])
        {
            [sectionController sectionDidLoad];
        }
    }
}

- (void)p_sendSectionDidUnload:(NSArray *)sectionControllers
{
    for (id sectionController in sectionControllers)
    {
        if ([sectionController respondsToSelector:@selector(sectionDidUnload)])
        {
            [sectionController sectionDidUnload];
        }
    }
}



@end
