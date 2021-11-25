class XComGameStateContext_HeadquartersOrderCS extends XComGameStateContext_HeadquartersOrder config(Game);

var config array<StatRanges> arrStatRanges;

static function CompleteTrainRookie(XComGameState AddToGameState, StateObjectReference ProjectRef)
{   
	local XComGameState_HeadquartersProjectConditionSoldier ProjectState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;
	local XComGameState_StaffSlot StaffSlotState;
	local XComGameStateHistory History;	
	local array<XComGameState_Item> EquippedImplants;
	local XComGameState_Item CombatSim;
    local int j, Bonus, NewStat, AbilityPointsGranted;
	local X2AbilityTemplate AbilityTemplate;
	local ClassAgnosticAbility Ability;
	local SoldierClassAbilityType AbilityType;
	local array<name> GrantedAbilities;	
	local name GrantedAbility;
	local name WeaponCat;

	History = `XCOMHISTORY;
	ProjectState = XComGameState_HeadquartersProjectConditionSoldier(`XCOMHISTORY.GetGameStateForObjectID(ProjectRef.ObjectID));

	if (ProjectState != none)
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		if (XComHQ != none)
		{
			XComHQ = XComGameState_HeadquartersXCom(AddToGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			XComHQ.Projects.RemoveItem(ProjectState.GetReference());
			AddToGameState.RemoveStateObject(ProjectState.ObjectID);
		}

		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ProjectState.ProjectFocus.ObjectID));
		if (UnitState != none)
		{
			// Set the soldier status back to active
			UnitState = XComGameState_Unit(AddToGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
            UnitState.SetStatus(eStatus_Active);
            
            EquippedImplants = UnitState.GetAllItemsInSlot(eInvSlot_CombatSim);

            if (EquippedImplants.length > 0)
            {
                foreach EquippedImplants(CombatSim)
                {
                    UnitState.UnapplyCombatSimStats(CombatSim);
                }
            }			
            
            // Update stat first
            j = default.arrStatRanges.find('Stat', ProjectState.ConditionStat);
            Bonus = class'X2DownloadableContentInfo_WOTC_SoldierConditioning'.static.RollBonus(UnitState.ComInt, default.arrStatRanges[j]);
			ProjectState.StatBonus = Bonus;
            NewStat = UnitState.GetMaxStat(ProjectState.ConditionStat) + Bonus;
            UnitState.SetBaseMaxStat(ProjectState.ConditionStat, NewStat);    

            `LOG("Which stat:" @ProjectState.ConditionStat, class'X2DownloadableContentInfo_WOTC_SoldierConditioning'.default.bEnableLog, 'WOTC_SolderConditioning');
            `LOG("Bonus:" @Bonus, class'X2DownloadableContentInfo_WOTC_SoldierConditioning'.default.bEnableLog, 'WOTC_SolderConditioning');
            `LOG("NewStat:" @NewStat, class'X2DownloadableContentInfo_WOTC_SoldierConditioning'.default.bEnableLog, 'WOTC_SolderConditioning');

            // Give Ability Points
            `LOG("UnitState.AbilityPoints (before):" @UnitState.AbilityPoints, class'X2DownloadableContentInfo_WOTC_SoldierConditioning'.default.bEnableLog, 'WOTC_SolderConditioning');
			AbilityPointsGranted = class'X2DownloadableContentInfo_WOTC_SoldierConditioning'.static.GiveAbilityPoints(UnitState.ComInt);
            UnitState.AbilityPoints += AbilityPointsGranted;
			ProjectState.AbilityPointsGranted = AbilityPointsGranted;
            `LOG("UnitState.AbilityPoints (after):" @UnitState.AbilityPoints, class'X2DownloadableContentInfo_WOTC_SoldierConditioning'.default.bEnableLog, 'WOTC_SolderConditioning'); 

            // Grant abilities
            class'X2DownloadableContentInfo_WOTC_SoldierConditioning'.static.GetAbilities(UnitState.ComInt, GrantedAbilities, UnitState);			
			ProjectState.GrantedAbilities = GrantedAbilities;

            foreach GrantedAbilities(GrantedAbility){
                AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(GrantedAbility);
                
				if(AbilityTemplate != none)
				{
					AbilityType.AbilityName = AbilityTemplate.DataName;
					`LOG("Ability:" @AbilityTemplate.DataName, class'X2DownloadableContentInfo_WOTC_SoldierConditioning'.default.bEnableLog, 'WOTC_SolderConditioning'); 

					WeaponCat = class'X2DownloadableContentInfo_WOTC_SoldierConditioning'.static.GetWeaponCatByAbility(AbilityType.AbilityName);

					if (WeaponCat != '')
					{
						AbilityType.ApplyToWeaponSlot = class'X2DownloadableContentInfo_WOTC_SoldierConditioning'.static.GetInventorySlotForWeaponCat(WeaponCat, UnitState.GetSoldierClassTemplate());
						if (AbilityType.ApplyToWeaponSlot == eInvSlot_Unknown) continue; // Do not grant this ability as something has gone wrong
					}

					Ability.AbilityType = AbilityType;
					Ability.bUnlocked = true;
					Ability.iRank = 0;
					UnitState.bSeenAWCAbilityPopup = true;
					UnitState.AWCAbilities.AddItem(Ability);

					ProjectState.AbilityTemplate = AbilityTemplate;
				}
				else
				{
					`LOG("Invalid ability:" @GrantedAbility, class'X2DownloadableContentInfo_WOTC_SoldierConditioning'.default.bEnableLog, 'WOTC_SolderConditioning');
				}
            }        

			// Will reduction
            class'X2DownloadableContentInfo_WOTC_SoldierConditioning'.static.GetReducedWill(UnitState, AddToGameState);    

            // Set unit value so each soldier can only do this training one time
            UnitState.SetUnitFloatValue('TR_SoldierConditioning', 1.0, eCleanup_Never);
                            
            if (EquippedImplants.length > 0)
            {
                foreach EquippedImplants(CombatSim)
                {
                    UnitState.ApplyCombatSimStats(CombatSim);
                }
            }

			// Remove the soldier from the staff slot
			StaffSlotState = UnitState.GetStaffSlot();
			if (StaffSlotState != none)
			{
				StaffSlotState.EmptySlot(AddToGameState);
			}
		}
	}
}

static function IssueHeadquartersOrderCS(const out HeadquartersOrderInputContext UseInputContext)
{
	local XComGameStateContext_HeadquartersOrder NewOrderContext;

	NewOrderContext = XComGameStateContext_HeadquartersOrder(class'XComGameStateContext_HeadquartersOrderCS'.static.CreateXComGameStateContext());
	NewOrderContext.InputContext = UseInputContext;

	`GAMERULES.SubmitGameStateContext(NewOrderContext);
}