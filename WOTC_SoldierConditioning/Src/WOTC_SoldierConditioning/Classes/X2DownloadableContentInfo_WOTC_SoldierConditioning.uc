class X2DownloadableContentInfo_WOTC_SoldierConditioning extends X2DownloadableContentInfo;

struct AbilityPointRange
{
	var int MinBonus;
	var int MaxBonus;
};

struct AbilityGrant
{
	var int Bonus;
	var int ChanceForAdditional;
};

struct AbilityByWeaponCatData
{
	var name WeaponCat;	
	var name AbilityName;	
};

var config bool bEnableLog;
var config array<int> arrComIntBonus;
var config array<AbilityPointRange> arrAbilityPointRange;
var config array<name> arrAbilityList;
var config array<name> arrExcludedAbility;
var config array<AbilityGrant> arrNoOfAbilities;
var config array<int> arrConditionSoldierDays;
var config float fRankScalar;
var config float fWillScalar;
var config bool bUseThisAbilityList;
var config array<float> arrComIntScalar;
var config array<AbilityByWeaponCatData> arrAbilitiesByWeaponCat;
var config bool bDefaultAbilityPool;
var config array<name> arrTrainingCenterCustomSlots;

static event OnLoadedSavedGame()
{
	AddSlotToExistingFacility('TR_ConditionSoldierSlot', 'RecoveryCenter');
}

static function AddSlotToExistingFacility(name SlotTemplateName, name FacilityName)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_StaffSlot StaffSlotState, StaffSlotStateExisting;
	local XComGameState NewGameState;
	local X2StaffSlotTemplate StaffSlotTemplate;
	local int i;	
	local bool bHasSlot;
	local X2StrategyElementTemplateManager StratMgr;	
	
	`LOG("Attempting to update built facility", default.bEnableLog, 'WOTC_SolderConditioning');

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Soldier Conditioning -- Adding New Slot");	

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	FacilityState = XComHQ.GetFacilityByName(FacilityName);

	if (FacilityState != none)
	{
		`LOG("Found facility state", default.bEnableLog, 'WOTC_SolderConditioning');
		FacilityState = XComGameState_FacilityXCom(NewGameState.ModifyStateObject(class'XComGameState_FacilityXCom', FacilityState.ObjectID));

		bHasSlot = false;
		for ( i = 0; i < FacilityState.StaffSlots.length; i++)
		{
			StaffSlotStateExisting = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(FacilityState.StaffSlots[i].ObjectID));
			if ( StaffSlotStateExisting.GetMyTemplateName() == SlotTemplateName )
			{
				bHasSlot = true;
				break;
			}
		}

		if (!bHasSlot)
		{
			`LOG("Slot not found so add it", default.bEnableLog, 'WOTC_SolderConditioning');
			StaffSlotTemplate = X2StaffSlotTemplate(StratMgr.FindStrategyElementTemplate(SlotTemplateName));
			StaffSlotState = StaffSlotTemplate.CreateInstanceFromTemplate(NewGameState);
			StaffSlotState.UnlockSlot();
			StaffSlotState.Facility = FacilityState.GetReference();

			FacilityState.StaffSlots.AddItem(StaffSlotState.GetReference());

			`GAMERULES.SubmitGameState(NewGameState);	
		}
		else 
		{ 
			`LOG("Slot found so nothing needs to be done", default.bEnableLog, 'WOTC_SolderConditioning');
			`XCOMHISTORY.CleanupPendingGameState(NewGameState);
		}
		
	}
	else
	{
		`LOG("Facility not built yet so we good", default.bEnableLog, 'WOTC_SolderConditioning');
		`XCOMHISTORY.CleanupPendingGameState(NewGameState);
	}
} 

static event OnPostTemplatesCreated()
{
    NewSlot_UpdateTemplate();
}

static function NewSlot_UpdateTemplate()
{
	AddSlotToFacility('RecoveryCenter', 'TR_ConditionSoldierSlot', false);		
}

static function AddSlotToFacility(name Facility, name StaffSlot, optional bool StartsLocked = true)
{
	local X2StrategyElementTemplateManager TemplateManager;
	local X2FacilityTemplate FacilityTemplate;
	local StaffSlotDefinition StaffSlotDef;	
	local int j;
	local array<X2DataTemplate>	 DataTemplates;	

	TemplateManager = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();	

	TemplateManager.FindDataTemplateAllDifficulties(Facility, DataTemplates);

	StaffSlotDef.StaffSlotTemplateName = StaffSlot;
	StaffSlotDef.bStartsLocked = StartsLocked;

	`LOG("DataTemplates.Length = " $ DataTemplates.Length, default.bEnableLog, 'WOTC_SolderConditioning');
	for ( j = 0; j < DataTemplates.Length; j++ )
	{
		FacilityTemplate = X2FacilityTemplate(DataTemplates[j]);
		if ( FacilityTemplate != none )
		{
			if ( FacilityTemplate.StaffSlotDefs.find('StaffSlotTemplateName', StaffSlot) == INDEX_NONE )
			{
				`LOG(StaffSlot $ " not found in facility template of " $ FacilityTemplate, default.bEnableLog, 'WOTC_SolderConditioning');
				`LOG("Index of FacilityTemplate.StaffSlotDefs = " $ FacilityTemplate.StaffSlotDefs.find('StaffSlotTemplateName', StaffSlot), default.bEnableLog, 'WOTC_SolderConditioning');
				FacilityTemplate.StaffSlotDefs.AddItem(StaffSlotDef);
			}
			else
			{
				`LOG(StaffSlot $ " found in facility template of " $ FacilityTemplate, default.bEnableLog, 'WOTC_SolderConditioning');
				`LOG("Index of FacilityTemplate.StaffSlotDefs = " $ FacilityTemplate.StaffSlotDefs.find('StaffSlotTemplateName', StaffSlot), default.bEnableLog, 'WOTC_SolderConditioning');
			}

			// This prevents idle staff message from showing up when they are staffed into this new slot
			FacilityTemplate.IsFacilityProjectActiveFn = IsRecoveryCenterProjectActiveOverride;
		}
	}
}

static function bool IsRecoveryCenterProjectActiveOverride(StateObjectReference FacilityRef)
{
	local XComGameStateHistory History;	
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_StaffSlot StaffSlot;	
	local int i;

	History = `XCOMHISTORY;	
	FacilityState = XComGameState_FacilityXCom(History.GetGameStateForObjectID(FacilityRef.ObjectID));
	
	for (i = 0; i < FacilityState.StaffSlots.Length; i++)
	{
		StaffSlot = FacilityState.GetStaffSlot(i);
		// Special handling: If its our slot, just pretend that there is an active project
		if (StaffSlot.IsSlotFilled() && default.arrTrainingCenterCustomSlots.find(StaffSlot.GetMyTemplateName()) != INDEX_NONE)
		{
			return true;
		}
	}
	// Then we call the legacy method for compatibility with other mods
	return class'X2StrategyElement_XpackFacilities'.static.IsRecoveryCenterProjectActive(FacilityRef);
}

// Get bonus stats from training
static function int RollBonus(ECombatIntelligence ComInt, StatRanges Range)
{
    local int RandRoll, Bonus, Plus, PartBonus;
    local float Percent, ImprovedRoll;

    RandRoll = `SYNC_RAND_STATIC(100);
    ImprovedRoll = RandRoll + default.arrComIntBonus[ComInt];

    if(ImprovedRoll > 100) ImprovedRoll = 100;

    Plus = Range.MaxBonus - Range.MinBonus + 1;
    Percent = ImprovedRoll/100.0;
    PartBonus = Round(Plus * Percent);
    Bonus = PartBonus + Range.MinBonus - 1;

    if(Bonus < 1) Bonus = 1;

    `LOG("RandRoll:" @RandRoll, default.bEnableLog, 'WOTC_SolderConditioning');
    `LOG("ImprovedRoll:" @ImprovedRoll, default.bEnableLog, 'WOTC_SolderConditioning');
    `LOG("Plus:" @Plus, default.bEnableLog, 'WOTC_SolderConditioning');
    `LOG("Percent:" @Percent, default.bEnableLog, 'WOTC_SolderConditioning');
    `LOG("PartBonus:" @PartBonus, default.bEnableLog, 'WOTC_SolderConditioning');

    return Bonus;
}

// Get ability points from training
static function int GiveAbilityPoints(ECombatIntelligence ComInt)
{
	local int RandRoll, Plus, PartBonus, Bonus;
	local float Percent;

	RandRoll = `SYNC_RAND_STATIC(100);
	Percent = RandRoll/100.0;
	Plus = default.arrAbilityPointRange[ComInt].MaxBonus - default.arrAbilityPointRange[ComInt].MinBonus + 1;
	PartBonus = Round(Plus * Percent);
	Bonus = PartBonus + default.arrAbilityPointRange[ComInt].MinBonus - 1;

	if(Bonus < 1) Bonus = 1;

    `LOG("RandRoll:" @RandRoll, default.bEnableLog, 'WOTC_SolderConditioning');    
    `LOG("Plus:" @Plus, default.bEnableLog, 'WOTC_SolderConditioning');
    `LOG("Percent:" @Percent, default.bEnableLog, 'WOTC_SolderConditioning');
    `LOG("PartBonus:" @PartBonus, default.bEnableLog, 'WOTC_SolderConditioning');

	return Bonus;
}

// Get abilities to be granted
static function GetAbilities(ECombatIntelligence ComInt, out array<name> Abilities, XComGameState_Unit UnitState)
{
	local int i, NumberToRoll, RandRoll;
	local array<name> AbilitiesToRoll;
	local array<name> ClassTemplateAbilities;
	local name AbilityName;	

	// Building the ability pool: Abilities from config
	if(default.bUseThisAbilityList)
	{
		foreach default.arrAbilityList(AbilityName)
		{			
			// Validate the abilities added via config
			if(class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityName) != none 
				&& AbilitiesToRoll.Find(AbilityName) < 1
				&& !HasAbilityInTree(UnitState, AbilityName))
			{
				AbilitiesToRoll.AddItem(AbilityName);
				`LOG("Added Ability from config to Ability pool:" @AbilityName, default.bEnableLog, 'WOTC_SolderConditioning');
			}
		}
	}

	// Building the ability pool: Abilities from class template: either from random deck or from AWC depending on class template
	GetClassTemplateAbilities(UnitState, ClassTemplateAbilities);

	for(i = 0; i < ClassTemplateAbilities.Length; i++)
	{
		if(AbilitiesToRoll.find(ClassTemplateAbilities[i]) < 0)
		{
			AbilitiesToRoll.AddItem(ClassTemplateAbilities[i]);
			`LOG("Added Ability from class template info to Ability pool:" @ClassTemplateAbilities[i], default.bEnableLog, 'WOTC_SolderConditioning');
		}
	}

	// Building the ability pool: Weapon specific abilities
	IncludeWeaponSpecificAbilities(AbilitiesToRoll, UnitState);

	// Pull random abilities from the pool
	for(i = 0; i < default.arrNoOfAbilities[ComInt].Bonus; i++)
	{
		if (AbilitiesToRoll.Length <= 0) break;
		
		NumberToRoll = AbilitiesToRoll.Length;
		RandRoll = `SYNC_RAND_STATIC(NumberToRoll);
		Abilities.AddItem(AbilitiesToRoll[RandRoll]);
		`LOG("Granted Ability:" @AbilitiesToRoll[RandRoll], default.bEnableLog, 'WOTC_SolderConditioning');
		AbilitiesToRoll.Remove(RandRoll, 1);

		`LOG("NumberToRoll:" @NumberToRoll, default.bEnableLog, 'WOTC_SolderConditioning');
		`LOG("RandRoll:" @RandRoll, default.bEnableLog, 'WOTC_SolderConditioning');		
	}

	// If there is a chance to get additional ability
	if(default.arrNoOfAbilities[ComInt].ChanceForAdditional > 0 
		&& default.arrNoOfAbilities[ComInt].ChanceForAdditional > `SYNC_RAND_STATIC(100)
		&& AbilitiesToRoll.Length > 0
		)
	{	
		// Uh.. this one a bit more optimised
		Abilities.AddItem(AbilitiesToRoll[`SYNC_RAND_STATIC(AbilitiesToRoll.Length)]);
		`LOG("Granted Ability:" @Abilities[Abilities.Length -1], default.bEnableLog, 'WOTC_SolderConditioning');
		AbilitiesToRoll.Remove(RandRoll, 1);	
	}
}

// HELPER: Get abilities depending on soldier class template
// If soldier class has random deck, that's where the abilities are grabbed
// Else grab AWC abilities (which is a lot)
static function GetClassTemplateAbilities(XComGameState_Unit UnitState, out array<name> ClassTemplateAbilities)
{	
	local array<SoldierClassAbilityType> CrossClassAbilities;
	local SoldierClassAbilityType stCrossClassAbilities;	
	local SoldierClassRandomAbilityDeck RandomDeck;	
	
	if (!default.bDefaultAbilityPool) return;

	CrossClassAbilities = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager().GetCrossClassAbilities_CH(UnitState.AbilityTree);

	// If the class template does not have random ability decks, we take all cross class abilities
	// if(UnitState.GetSoldierClassTemplate().RandomAbilityDecks.Length < 1)	
	// {
	// 	foreach CrossClassAbilities(stCrossClassAbilities)
	// 	{
	// 		// static function bool HasAbilityInTree(XComGameState_Unit UnitState, name AbilityName)
	// 		// if(!UnitState.HasAbilityFromAnySource(stCrossClassAbilities.AbilityName))
	// 		if(!HasAbilityInTree(UnitState, stCrossClassAbilities.AbilityName))
	// 		{
	// 			ClassTemplateAbilities.AddItem(stCrossClassAbilities.AbilityName);
	// 			`LOG("Added AWC ability:" @stCrossClassAbilities.AbilityName, default.bEnableLog, 'WOTC_SolderConditioning');
	// 		}
	// 	}
	// }
	// Else we take abilities from random deck
	// else
	// {
	// 	foreach UnitState.GetSoldierClassTemplate().RandomAbilityDecks(RandomDeck)
	// 	{
	// 		foreach RandomDeck.Abilities(stCrossClassAbilities)
	// 		{
	// 			// if(!UnitState.HasSoldierAbility(stCrossClassAbilities.AbilityName))
	// 			// if(!UnitState.HasAbilityFromAnySource(stCrossClassAbilities.AbilityName))
	// 			if(!HasAbilityInTree(UnitState, stCrossClassAbilities.AbilityName))
	// 			{
	// 				ClassTemplateAbilities.AddItem(stCrossClassAbilities.AbilityName);
	// 				`LOG("Added ability from Random Deck:" @stCrossClassAbilities.AbilityName, default.bEnableLog, 'WOTC_SolderConditioning');
	// 			}
	// 		}
	// 	}
	// }

	if(class'CHHelpers'.default.ClassesExcludedFromAWCRoll.Find(UnitState.GetSoldierClassTemplateName()) == INDEX_NONE)
	{
		foreach CrossClassAbilities(stCrossClassAbilities)
		{		
			if(!HasAbilityInTree(UnitState, stCrossClassAbilities.AbilityName) && default.arrExcludedAbility.Find(stCrossClassAbilities.AbilityName) == INDEX_NONE
				&& class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(stCrossClassAbilities.AbilityName) != none)
			{
				ClassTemplateAbilities.AddItem(stCrossClassAbilities.AbilityName);
				`LOG("Added AWC ability:" @stCrossClassAbilities.AbilityName, default.bEnableLog, 'WOTC_SolderConditioning');
			}
		}
	}
	else
	{
		foreach UnitState.GetSoldierClassTemplate().RandomAbilityDecks(RandomDeck)
		{
			foreach RandomDeck.Abilities(stCrossClassAbilities)
			{
				if(!HasAbilityInTree(UnitState, stCrossClassAbilities.AbilityName) && default.arrExcludedAbility.Find(stCrossClassAbilities.AbilityName) == INDEX_NONE
					&& class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(stCrossClassAbilities.AbilityName) != none)
				{					
					ClassTemplateAbilities.AddItem(stCrossClassAbilities.AbilityName);
					`LOG("Added Random Deck ability:" @stCrossClassAbilities.AbilityName, default.bEnableLog, 'WOTC_SolderConditioning');
				}
			}
		}		
	}
}

// HELPER: To get no of training duration
static function int GetTrainingDays(XComGameState_Unit UnitState)
{
	local int BaseDays, SoldierRank, DaysByRank, DaysFinal;
	local ECombatIntelligence ComInt;

	BaseDays = `ScaleStrategyArrayInt(default.arrConditionSoldierDays);
	SoldierRank = UnitState.GetSoldierRank();
	ComInt = UnitState.ComInt;

	DaysByRank = round(BaseDays * default.fRankScalar * SoldierRank);
	if(DaysByRank < BaseDays) DaysByRank = BaseDays;	// Don't go lower than config
	`LOG("DaysByRank:" @DaysByRank, default.bEnableLog, 'WOTC_SolderConditioning');

	DaysFinal = DaysByRank - round(DaysByRank * default.arrComIntScalar[ComInt]);
	`LOG("DaysFinal:" @DaysFinal, default.bEnableLog, 'WOTC_SolderConditioning');

	if(DaysFinal < 1) DaysFinal = 1;	// Safeguard
	`LOG("DaysFinalFinal:" @DaysFinal, default.bEnableLog, 'WOTC_SolderConditioning');

	return DaysFinal;
}

// HELPER: Determine will loss
static function GetReducedWill(out XComGameState_Unit UnitState, XComGameState AddToGameState)
{
	local int TrainingDays, CurrentWill, ReducedWill;
	local XComGameState_HeadquartersProjectRecoverWill WillProject;

	TrainingDays = GetTrainingDays(UnitState);
	CurrentWill = UnitState.GetCurrentStat(eStat_Will);

	// ReducedWill = CurrentWill - ((TrainingDays / 7) * default.fWillScalar * UnitState.GetMaxStat(eStat_Will));
	ReducedWill = CurrentWill - (TrainingDays * default.fWillScalar * UnitState.GetMaxStat(eStat_Will));	

	if (ReducedWill < 1) ReducedWill = 1;

	// Reduce will
	UnitState.SetCurrentStat(eStat_Will, ReducedWill);
	// Update mental state
	UnitState.UpdateMentalState();

	// Depending on the mental state, start the necessary project to bring them up to full
	if(UnitState.GetMentalState() != eMentalState_Ready)
	{
		class'XComGameStateContext_HeadquartersOrder'.static.StartUnitHealing(AddToGameState, UnitState.GetReference());
	}
	else
	{
		// Start Will Recovery Project
		foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_HeadquartersProjectRecoverWill', WillProject)
		{
			if (WillProject.ProjectFocus == UnitState.GetReference())
			{
				`XCOMHQ.Projects.RemoveItem(WillProject.GetReference());
				AddToGameState.RemoveStateObject(WillProject.ObjectID);
				break;
			}
		}

		// NewUnitState.SetCurrentStat(eStat_Will, NewUnitState.GetMinWillForMentalState(eMentalState_Ready));
		// NewUnitState.UpdateMentalState();
		WillProject = XComGameState_HeadquartersProjectRecoverWill(AddToGameState.CreateNewStateObject(class'XComGameState_HeadquartersProjectRecoverWill'));
		WillProject.SetProjectFocus(UnitState.GetReference(), AddToGameState);
		`XCOMHQ.Projects.AddItem(WillProject.GetReference());
		`GAME.GetGeoscape().m_kBase.m_kCrewMgr.RefreshFacilityPatients();
	}

	`LOG("Will (before):" @CurrentWill, default.bEnableLog, 'WOTC_SolderConditioning');
	`LOG("Will (after):" @UnitState.GetCurrentStat(eStat_Will), default.bEnableLog, 'WOTC_SolderConditioning');
}

// HELPER: Check if the ability is already in the soldier skill tree
static function bool HasAbilityInTree(XComGameState_Unit UnitState, name AbilityName)
{
	local SoldierRankAbilities Abilities;
	local SoldierClassAbilityType Ability;

	foreach UnitState.AbilityTree(Abilities)
	{
		foreach Abilities.Abilities(Ability)
		{
			if(Ability.AbilityName == AbilityName)
			{
				return true;
			}
		}
	}
	return false;
}

// HELPER: Include weapon specific abilities
static function IncludeWeaponSpecificAbilities(out array<name> AbilitiesToRoll, XComGameState_Unit UnitState)
{
	local X2SoldierClassTemplate SoldierClassTemplate;
	local AbilityByWeaponCatData AbilityByWeaponCat;
	local int i;	

	if (!default.bUseThisAbilityList) return;

	SoldierClassTemplate = UnitState.GetSoldierClassTemplate();

	for (i = 0; i < SoldierClassTemplate.AllowedWeapons.Length; i++)
	{			
		foreach default.arrAbilitiesByWeaponCat(AbilityByWeaponCat)
		{
			// Not allowed by soldier class template. Also kills invalid weapon cat from this mod's config. Skip.
			if (AbilityByWeaponCat.WeaponCat != SoldierClassTemplate.AllowedWeapons[i].WeaponType) continue;			
			
			// Already in ability pool (which could have come from AWC perks or random deck). Skip.
			if (AbilitiesToRoll.Find(AbilityByWeaponCat.AbilityName) != INDEX_NONE) continue;
			
			// Invalid ability. Skip.
			if (class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityByWeaponCat.AbilityName) == none) continue;
			
			// Already in tree. Skip.
			if (HasAbilityInTree(UnitState, AbilityByWeaponCat.AbilityName)) continue;
			
			// Excluded ability (this can only happen if this mod is configured in a weird way)
			if (default.arrExcludedAbility.Find(AbilityByWeaponCat.AbilityName) != INDEX_NONE) continue;
				
			// Okay we good 
			AbilitiesToRoll.AddItem(AbilityByWeaponCat.AbilityName);			
		}
	}	
}

// HELPER: Determine inventory slot based on weapon category
static function EInventorySlot GetInventorySlotForWeaponCat(name WeaponCat, X2SoldierClassTemplate SoldierClassTemplate)
{
	local SoldierClassWeaponType AllowedWeapon;

	if (WeaponCat == '' || SoldierClassTemplate == none) return eInvSlot_Unknown;

	foreach SoldierClassTemplate.AllowedWeapons(AllowedWeapon)
	{
		if (AllowedWeapon.WeaponType == WeaponCat && 
			(AllowedWeapon.SlotType == eInvSlot_PrimaryWeapon || AllowedWeapon.SlotType == eInvSlot_SecondaryWeapon)
			)
		{
			return AllowedWeapon.SlotType;
		}
	}

	return eInvSlot_Unknown;
}

// HELPER: Determine weapon category based on ability configured. Used in conjunction with GetInventorySlotForWeaponCat
static function name GetWeaponCatByAbility(name AbilityName)
{
	local AbilityByWeaponCatData AbilityByWeaponCat;

	foreach default.arrAbilitiesByWeaponCat(AbilityByWeaponCat)
	{
		if (AbilityByWeaponCat.AbilityName == AbilityName) return AbilityByWeaponCat.WeaponCat;	
	}

	return '';
}

// For the popup when soldier finishes training
static function bool DisplayQueuedDynamicPopup(DynamicPropertySet PropertySet)
{
	if (PropertySet.PrimaryRoutingKey == 'UIAlert_ConditionSoldier')
	{
		CallUIAlert_ConditionSoldier(PropertySet);
		return true;
	}

	return false;
}

static function CallUIAlert_ConditionSoldier(const out DynamicPropertySet PropertySet)
{
	local XComHQPresentationLayer Pres;
	local UIAlert_ConditionSoldier Alert;

	Pres = `HQPRES;

	Alert = Pres.Spawn(class'UIAlert_ConditionSoldier', Pres);
	Alert.DisplayPropertySet = PropertySet;
	Alert.eAlertName = PropertySet.SecondaryRoutingKey;

	Pres.ScreenStack.Push(Alert);
}