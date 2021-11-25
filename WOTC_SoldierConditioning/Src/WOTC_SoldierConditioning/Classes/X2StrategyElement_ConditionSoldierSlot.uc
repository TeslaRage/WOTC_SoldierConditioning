class X2StrategyElement_ConditionSoldierSlot extends X2StrategyElement_DefaultStaffSlots config(Game);

var config array<name> arrExcludedClassesFromSlot;
var config int MininumRank;

//---------------------------------------------------------------------------------------
static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> StaffSlots;

	StaffSlots.AddItem(CreateCSoldierSlotTemplate());
		
	return StaffSlots;
}

//#############################################################################################
//----------------   NEW SLOT    --------------------------------------------------------------
//#############################################################################################
static function X2DataTemplate CreateCSoldierSlotTemplate()
{
	local X2StaffSlotTemplate Template;
	local int i;

	Template = CreateStaffSlotTemplate('TR_ConditionSoldierSlot');
	Template.bSoldierSlot = true;
	Template.bRequireConfirmToEmpty = true;
	Template.bPreventFilledPopup = true;
	Template.UIStaffSlotClass = class'UIFacility_ConditionSoldierSlot';
	Template.AssociatedProjectClass = class'XComGameState_HeadquartersProjectConditionSoldier';
	Template.FillFn = CS_FillFn;
	Template.EmptyStopProjectFn = CS_EmptyStopProjectFn;
	Template.ShouldDisplayToDoWarningFn = CS_ShouldDisplayToDoWarningFn;
	Template.GetSkillDisplayStringFn = "";
	Template.GetBonusDisplayStringFn = CS_GetBonusDisplayStringFn;
	Template.IsUnitValidForSlotFn = CS_IsUnitValidForSlotFn;
	Template.MatineeSlotName = "Soldier";

	for (i = 0; i < default.arrExcludedClassesFromSlot.length; i++)
	{	
		Template.ExcludeClasses.AddItem(default.arrExcludedClassesFromSlot[i]);
	}
	
	return Template;
}

static function CS_FillFn(XComGameState NewGameState, StateObjectReference SlotRef, StaffUnitInfo UnitInfo, optional bool bTemporary = false)
{
	local XComGameState_Unit NewUnitState;
	local XComGameState_StaffSlot NewSlotState;
	local XComGameState_HeadquartersXCom NewXComHQ;	
	local XComGameState_HeadquartersProjectConditionSoldier ProjectState;
	local StateObjectReference EmptyRef;
	local int SquadIndex;

	FillSlot(NewGameState, SlotRef, UnitInfo, NewSlotState, NewUnitState);
	NewXComHQ = GetNewXComHQState(NewGameState);	
	
	ProjectState = XComGameState_HeadquartersProjectConditionSoldier(NewGameState.CreateNewStateObject(class'XComGameState_HeadquartersProjectConditionSoldier'));
	ProjectState.SetProjectFocus(UnitInfo.UnitRef, NewGameState, NewSlotState.Facility);

	NewUnitState.SetStatus(eStatus_Training);
	NewXComHQ.Projects.AddItem(ProjectState.GetReference());

	// Remove their gear
	NewUnitState.MakeItemsAvailable(NewGameState, false);
	
	// If the unit undergoing training is in the squad, remove them
	SquadIndex = NewXComHQ.Squad.Find('ObjectID', UnitInfo.UnitRef.ObjectID);
	if (SquadIndex != INDEX_NONE)
	{
		// Remove them from the squad
		NewXComHQ.Squad[SquadIndex] = EmptyRef;
	}
}

static function CS_EmptyStopProjectFn(StateObjectReference SlotRef)
{
	local HeadquartersOrderInputContext OrderInput;
	local XComGameState_StaffSlot SlotState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersProjectConditionSoldier ProjectState;	

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	SlotState = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(SlotRef.ObjectID));

	ProjectState = GetTrainProject(XComHQ, SlotState.GetAssignedStaffRef());	
	if (ProjectState != none)
	{		
		OrderInput.OrderType = eHeadquartersOrderType_CancelTrainRookie;
		OrderInput.AcquireObjectReference = ProjectState.GetReference();
		
		class'XComGameStateContext_HeadquartersOrderCS'.static.IssueHeadquartersOrderCS(OrderInput);
	}
}

static function bool CS_ShouldDisplayToDoWarningFn(StateObjectReference SlotRef)
{
	return false;
}

static function XComGameState_HeadquartersProjectConditionSoldier GetTrainProject(XComGameState_HeadquartersXCom XComHQ, StateObjectReference UnitRef)
{
	local int idx;
	local XComGameState_HeadquartersProjectConditionSoldier ProjectState;

	for (idx = 0; idx < XComHQ.Projects.Length; idx++)
	{
		ProjectState = XComGameState_HeadquartersProjectConditionSoldier(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.Projects[idx].ObjectID));

		if (ProjectState != none)
		{
			if (UnitRef == ProjectState.ProjectFocus)
			{
				return ProjectState;
			}
		}
	}

	return none;
}

static function string CS_GetBonusDisplayStringFn(XComGameState_StaffSlot SlotState, optional bool bPreview)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersProjectConditionSoldier ProjectState;
	local string Contribution;

	if (SlotState.IsSlotFilled())
	{
		XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
		ProjectState = GetTrainProject(XComHQ, SlotState.GetAssignedStaffRef());

		if (ProjectState.GetTrainingClassTemplate().DisplayName != "")
			Contribution = Caps(ProjectState.GetTrainingClassTemplate().DisplayName);
		else
			Contribution = SlotState.GetMyTemplate().BonusDefaultText;
	}

	return GetBonusDisplayString(SlotState, "%SKILL", Contribution);
}

static function bool CS_IsUnitValidForSlotFn(XComGameState_StaffSlot SlotState, StaffUnitInfo UnitInfo)
{
	local XComGameState_Unit Unit;
	local UnitValue kUnitValue;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));

	// Check unit value. This training is only allowed one time per soldier
	if(Unit.GetUnitValue('TR_SoldierConditioning', kUnitValue))
	{
		if(kUnitValue.fValue > 0) return false;
	}

	if (Unit.CanBeStaffed()
		&& Unit.IsSoldier()
		&& Unit.IsActive()
		&& Unit.GetRank() >= default.MininumRank
		&& SlotState.GetMyTemplate().ExcludeClasses.Find(Unit.GetSoldierClassTemplateName()) == INDEX_NONE) // Certain classes can't retrain their abilities (Psi Ops)
	{
		return true;
	}

	return false;
}