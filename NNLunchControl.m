//
//  NNLunchControl.m
//  lunchd
//
//  Created by MacRae Linton on 3/9/10.
//  Copyright 2010 Apple Inc.. All rights reserved.
//

#import "NNLunchControl.h"


@implementation NNLunchControl

@synthesize restaurants;
@synthesize people;

- (id) init
{
	self = [super init];
	if (self){
		DEBUGS = 0;
		
		NSLog(@"INININIT");
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSArray *defaultResturants = [NSArray arrayWithObjects:@"Cafe Macs",@"Wahoo's",@"In'n'out",
									 @"Thai Pepper",@"Rio",@"BBQ",nil];
		NSDictionary *appDefaults = [NSDictionary dictionaryWithObjectsAndKeys: defaultResturants,@"restaurants",nil];
		
		[defaults registerDefaults:appDefaults];
		
		people = [[NSMutableArray alloc] init];
		restaurants = [[NSMutableArray alloc] init];
		restaurantList = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void) dealloc
{
	[people release];
	[restaurants release];
	[super dealloc];
}

- (void)awakeFromNib
{
	NSLog(@"I HAVE AWOKEN");
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	//lets try putting a new view in the view. 
	NSArray *resturantNames = [defaults arrayForKey:@"restaurants"];
	for (NSString *rName in resturantNames){
		[self createNewRestaurantWithName:rName];
	}
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	NSLog(@"GAMEON");
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults stringForKey:@"name"]  == NULL){
		//setup getting the name. 
		NSLog(@"NO NAME YET, SETTING TO MACRAE");
		[defaults setObject:@"MacRae" forKey:@"name"];
	}
	
	
	
	mePerson = [[NNPerson alloc] initWithName:[defaults stringForKey:@"name"]];
	
	//This may need to be synced. Otherwise you could restart the app and use 
	//your veto over and over again.
	//No, you can't because when you drop out, you send a I'm gone message out that erases your veto. 
	//probably just need a "you" card
	usedVeto = NO;
	
	//probably want to set up a timer that will keep checking in? 
	//or are they all pushing info out. 
}

//---------

- (NNRestaurant *)createNewRestaurantWithName:(NSString *)name
{
	NNRestaurant *r = [[NNRestaurant alloc] initWithName:name];
	[restaurants addObject:r];
	NNRestaurantView *rView = [[NNRestaurantView alloc] initWithFrame:NSMakeRect(0, 0, 300, 60) andController:self];
	[rView setRepresentedRestaurant:r];
	[restaurantSSView addArrangedSubview:rView];
	//we always add to the bottom, then when things are changed, it updates?
	[restaurantList addObject:name];
	
	[self updateRestaurantPosition:r];
	
	return r;
}

- (NNPerson *)createNewPersonWithName:(NSString *)name
{
	NNPerson *p = [[NNPerson alloc] initWithName:name];
	[people addObject:p];
	NNPersonView *pView = [[NNPersonView alloc] initWithFrame:NSMakeRect(0, 0, 300, 60) andController:self];
	[pView setRepresentedPerson:p];
	[personSSView addArrangedSubview:pView];
	
	[self updatePersonPosition:p];
	
	return p;
}


// -------CONTROL FUNCTIONS
// TOP LEVEL:
- (IBAction)imIn:(id)sender
{
	NSLog(@"YOU ARE IN");
}
- (IBAction)imOut:(id)sender
{
	NSLog(@"YOU ARE OUT");
}


// Restraunts

- (IBAction)voteButtonPress:(id)sender
{
	NNRestaurant *rest = [(NNRestaurantView *)[sender superview] representedRestaurant];
	[rest giveVote];
	[self updateRestaurantPosition:rest];
}

- (IBAction)vetoButtonPress:(id)sender
{
	NNRestaurant *rest = [(NNRestaurantView *)[sender superview] representedRestaurant];
	[rest giveVeto];
	[self updateRestaurantPosition:rest];
}


//Add resturant goes to top of list. sorted by alphabet?
//When a resturant is chosen, it gets pushed to the bottom. 

- (void)updateRestaurantPosition:(NNRestaurant *)restaurant
{
	//initial pass is just move to top and bottom for vote and veto.
	//for now assume it was just changed to need moving. 
	int curIndex = [restaurants indexOfObject:restaurant];
	
	if ([restaurant votes] > 0){
		//this has been voted for, move it to the top.
		if (curIndex == 0){
			return;
		}
		[restaurants removeObjectAtIndex:curIndex];
		[restaurants insertObject:restaurant atIndex:0];
		
		[restaurantSSView slideViewAtIndex:curIndex toIndex:0];
	}else if ([restaurant votes] <= -1) {
		//move to the bottom. 
		if (curIndex == [restaurants count] -1){
			return;
		}
		[restaurants removeObjectAtIndex:curIndex];
		[restaurants addObject:restaurant];
		
		[restaurantSSView slideViewAtIndex:curIndex toIndex:[restaurants count] -1];
	}else {
		//need to move back to the middle. 
		//might be able to use this to generalize all of these just with this one.
		//that would keep the most voted ones at the top (what if I didn't even display the count?)
		int i;
		for (i = 0; i < [restaurants count]; i++){
			if ([[restaurants objectAtIndex:i] votes] <= 0){
				break;
			}
		}
		if (curIndex == i){
			return;
		}
		[restaurants removeObjectAtIndex:curIndex];
		[restaurants insertObject:restaurant atIndex:i];
		
		[restaurantSSView slideViewAtIndex:curIndex toIndex:i];
	}

}

- (void)updatePersonPosition:(NNPerson *)person
{
	NSLog(@"UNIMPLEMENTED person position updateing");
}

- (void)checkInWithAll:(id)sender
{
	NSLog(@"CHEKING IN");
}


- (void)dealWithMessage:(NNNMessage *)message
{
	NSString *personName = [message name];
	NNPerson *thePerson = nil;
	for (NNPerson *person in people){
		if ([[person name] isEqualToString:personName]){
			thePerson = person;
		}
	}
	if (thePerson == nil){
		//create new person and add it to people. 
		thePerson = [self createNewPersonWithName:personName];
	}
	//check and see if they are coming, and if that matches. 
	
	//If they are not coming, remove their current stuff from the thing.
	if ([thePerson state] != [message state]){
		if ([message state] == NNNotComingState){
			for (NSString *restName in [thePerson votes]){
				NNRestaurant *rest = [self objectWithName:restName fromArray:restaurants];
				[rest setVotes:[rest votes] - 1];
				[self updateRestaurantPosition:rest];
			}
			[thePerson setVotes:nil];
			NNRestaurant *vRest = [self objectWithName:[thePerson veto] fromArray:restaurants];
			[vRest setVotes:[vRest votes] +1];
			[thePerson setVeto:nil];
			[self updateRestaurantPosition:vRest];
			
			[thePerson setState:[message state]];
			[self updatePersonPosition:thePerson];
			
			
			NNRestaurant *rio = [self objectWithName:@"Rio" fromArray:restaurants];
			NSLog(@"RIO IS? %d",[rio votes]);
			
			return;
		}
	}
	
	
	
	if ([thePerson state] != [message state]){
		[thePerson setState:[message state]];
		[self updatePersonPosition:thePerson];
	}
	
	//TODO: Optimization, might should have a dictionary of names to objects instead of just arrays. (how preserve ordering? Don't worry about it?)
	
	//get thir list and see if they have anything you don't have.
	NSArray *newRestaurants = [self rightDiffBetweenArray:restaurantList andArray:[message restaurantList]];
	for (NSString *rest in newRestaurants){
		[self createNewRestaurantWithName:rest];
	}
	
	//go through all their votes and if they have new ones, update those restaurats and display them. 
	NSArray *newVotes = [self rightDiffBetweenArray:[thePerson votes] andArray:[message votes]];
	for (NSString *vote in newVotes){
		for (NNRestaurant *rest in restaurants){
			if ([[rest name] isEqualToString:vote]){
				if ([rest votes] <= -1){
					//Actually, this is probably OK. again, should be delegated to the object itself. 
					NSLog(@"Woah there, you shouldn't be voting for something that is vetoed. When you get my info that it is vetoed, that will be good.");
				} else {
					[rest setVotes:[rest votes] + 1];
					[self updateRestaurantPosition:rest];
				}
				break;
			}
		}
	}
	[thePerson setVotes:[NSMutableArray arrayWithArray:[message votes]]];
	
	//get their veto and axe a restaurant.
	for (NNRestaurant *rest in restaurants){
		if ([[rest name] isEqualToString:[message veto]]){
			if ([rest votes] >= 0){
				[rest setVotes:-1];
			}else {
				[rest setVotes:[rest votes] -1];
			}
			[self updateRestaurantPosition:rest];
			break;
		}
	}
	[thePerson setVeto:[message veto]];
	
}



//UTILITIES

//THis is a right diff, only finds what array 2 has that 1 does not have. 
- (NSArray *)rightDiffBetweenArray:(NSArray *)array1 andArray:(NSArray *)array2
{
	NSMutableArray *theDiff = [[[NSMutableArray alloc] initWithCapacity:5] autorelease];
	for ( id item in array2){
		if (![array1 containsObject:item]){
			[theDiff addObject:item];
		}
	}
	if ([theDiff count] == 0){
		theDiff = nil;
	}
	return theDiff;
}

- (id)objectWithName:(NSString *)name fromArray:(NSArray *)array
{
	for (id obj in array){
		if ([[obj name] isEqualToString:name]){
			return obj;
		}
	}
	return nil;
}


- (IBAction)debugButtonClick:(id)sender
{
	
	//test message:
	if (DEBUGS == 0){
		NNNMessage *message = [[NNNMessage alloc] init];
		[message setTag:0];
		[message setName:@"Henry Taggart"];
		[message setState:NNUndefinedState];
		[message setVeto:@"Rio"];
		[message setVotes:[NSArray arrayWithObjects:@"BBQ",@"Thai Pepper",nil]];
		[message setRestaurantList:[NSArray arrayWithObjects:@"Cafe Macs",@"Wahoo's",@"In'n'out",
									@"Thai Pepper",@"Rio",@"BBQ",@"Hardee's",nil]];
		
		[self dealWithMessage:message];
	}
	if (DEBUGS == 1){
		NNNMessage *message = [[NNNMessage alloc] init];
		[message setTag:0];
		[message setName:@"James Dempsy"];
		[message setState:NNComingState];
		[message setVeto:@"BBQ"];
		[message setVotes:[NSArray arrayWithObjects:@"In'n'out",@"Thai Pepper",nil]];
		[message setRestaurantList:[NSArray arrayWithObjects:@"Cafe Macs",@"Wahoo's",@"In'n'out",
									@"Thai Pepper",@"Rio",@"BBQ",nil]];
		
		[self dealWithMessage:message];
	}
	if (DEBUGS == 2){
		NNNMessage *message = [[NNNMessage alloc] init];
		[message setTag:1];
		[message setName:@"Henry Taggart"];
		[message setState:NNNotComingState];
		
		[self dealWithMessage:message];
	}
	
	DEBUGS ++;
	
	NSLog(@"DONE WITH DEBUG DEAL");
}

@end
