class UIChooseClass_ConditionSoldier extends UIChooseClass config(Game);

struct StatForConditioning
{
    var ECharStatType Stat;
	var string img;
};

struct StatRanges
{
    var ECharStatType Stat;
    var int MinBonus;
    var int MaxBonus;
};

var config array<StatForConditioning> arrStatForConditioning;

var localized string m_strStatTitle;
var localized string m_strStatDesc;

simulated function array<Commodity> ConvertClassesToCommodities()
{
	local array<Commodity> arrCommodoties;
	local Commodity StatsComm;
    local StatForConditioning stStatForConditioning;
    local XGParamTag LocTag;
    local XComGameState_Unit UnitState;
    local int j;
    
    UnitState = XComGameState_Unit(History.GetGameStateForObjectID(m_UnitRef.ObjectID));    

    LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));        
	
    foreach default.arrStatForConditioning(stStatForConditioning)
    {
        j = class'XComGameStateContext_HeadquartersOrderCS'.default.arrStatRanges.find('Stat', stStatForConditioning.Stat);

        LocTag.StrValue0 = class'X2TacticalGameRulesetDataStructures'.default.m_aCharStatLabels[stStatForConditioning.Stat];   
        LocTag.StrValue1 = UnitState.GetCombatIntelligenceLabel(); 
        LocTag.IntValue0 = class'X2DownloadableContentInfo_WOTC_SoldierConditioning'.default.arrComIntBonus[UnitState.ComInt];                
        LocTag.IntValue1 = class'XComGameStateContext_HeadquartersOrderCS'.default.arrStatRanges[j].MinBonus;
        LocTag.IntValue2 = class'XComGameStateContext_HeadquartersOrderCS'.default.arrStatRanges[j].MaxBonus;

        StatsComm.Title = LocTag.StrValue0 @m_strStatTitle;
        StatsComm.Image = stStatForConditioning.img;
        StatsComm.Desc = `XEXPAND.ExpandString(m_strStatDesc);
        StatsComm.OrderHours = class'X2DownloadableContentInfo_WOTC_SoldierConditioning'.static.GetTrainingDays(UnitState) * 24;
     
        arrCommodoties.AddItem(StatsComm);
    } 
	return arrCommodoties;
}

function bool OnClassSelected(int iOption)
{
	local XComGameState NewGameState;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_StaffSlot StaffSlotState;	
	local XComGameState_HeadquartersProjectConditionSoldier ProjectState;
	local StaffUnitInfo UnitInfo;		
	
	FacilityState = XComHQ.GetFacilityByName('RecoveryCenter');	
	StaffSlotState = FacilityState.GetEmptyStaffSlotByTemplate('TR_ConditionSoldierSlot');
	
	if (StaffSlotState != none)
	{
		// The Training project is started when the staff slot is filled. Pass in the NewGameState so the project can be found below.
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Staffing Condition Soldier Slot");
		UnitInfo.UnitRef = m_UnitRef;
		StaffSlotState.FillSlot(UnitInfo, NewGameState);
		
		// Find the new Training Project which was just created by filling the staff slot and set the class		
		foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersProjectConditionSoldier', ProjectState)
		{			
            ProjectState.ConditionStat = default.arrStatForConditioning[iOption].Stat;			
			break;
		}
		
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		`XSTRATEGYSOUNDMGR.PlaySoundEvent("StrategyUI_Staff_Assign");		
		RefreshFacility();
	}
    return true;
}

defaultproperties
{
	InputState = eInputState_Consume;

	bHideOnLoseFocus = true;	

	DisplayTag="UIDisplay_Academy"
	CameraTag="UIDisplay_Academy"
}