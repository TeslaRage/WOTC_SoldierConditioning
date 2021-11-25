class UIFacility_ConditionSoldierSlot extends UIFacility_AcademySlot dependson(UIPersonnel);

var localized string m_strConditionSoldierDialogTitle;
var localized string m_strConditionSoldierDialogText;
var localized string m_strStopConditionSoldierDialogTitle;
var localized string m_strStopConditionSoldierDialogText;
var localized string m_strNoSoldiersTooltip;
var localized string m_strSoldiersAvailableTooltip;

//-----------------------------------------------------------------------------
simulated function ShowDropDown()
{
	local XComGameState_StaffSlot StaffSlot;
	local XComGameState_Unit UnitState;
	local string StopTrainingText;

	StaffSlot = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(StaffSlotRef.ObjectID));

	if (StaffSlot.IsSlotEmpty())
	{
		OnConditioningSelected();
		// StaffContainer.ShowDropDown(self);		
	}
	else // Ask the user to confirm that they want to empty the slot and stop training
	{		
		UnitState = StaffSlot.GetAssignedStaff();
		StopTrainingText = m_strStopConditionSoldierDialogText;
		StopTrainingText = Repl(StopTrainingText, "%UNITNAME", UnitState.GetName(eNameType_RankFull));		

		ConfirmEmptyProjectSlotPopup(m_strStopConditionSoldierDialogTitle, StopTrainingText);
	}
}

simulated function OnConditioningSelected()
{
	if(IsDisabled)
		return;

	ShowSoldierList(eUIAction_Accept, none);
}

simulated function ShowSoldierList(eUIAction eAction, UICallbackData xUserData)
{
	local UIPersonnel_ConditionTraining kPersonnelList;
	local XComHQPresentationLayer HQPres;
	local XComGameState_StaffSlot StaffSlotState;
	
	if (eAction == eUIAction_Accept)
	{
		HQPres = `HQPRES;
		StaffSlotState = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(StaffSlotRef.ObjectID));

		//Don't allow clicking of Personnel List is active or if staffslot is filled
		if(HQPres.ScreenStack.IsNotInStack(class'UIPersonnel') && !StaffSlotState.IsSlotFilled())
		{
			kPersonnelList = Spawn( class'UIPersonnel_ConditionTraining', HQPres);
			kPersonnelList.m_eListType = eUIPersonnel_Soldiers;
			kPersonnelList.onSelectedDelegate = OnSoldierSelected;
			kPersonnelList.m_bRemoveWhenUnitSelected = true;
			kPersonnelList.SlotRef = StaffSlotRef;
			HQPres.ScreenStack.Push( kPersonnelList );
		}
	}
}

simulated function OnSoldierSelected(StateObjectReference UnitRef)
{
	local XComGameStateHistory History;	
	local XGParamTag LocTag;
	local TDialogueBoxData DialogData;
	local XComGameState_Unit Unit;
	local UICallbackData_StateObjectReference CallbackData;

	History = `XCOMHISTORY;
	Unit = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));	

	LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	LocTag.StrValue0 = Unit.GetName(eNameType_RankFull);	
	LocTag.StrValue1 = string(class'X2DownloadableContentInfo_WOTC_SoldierConditioning'.static.GetTrainingDays(Unit));

	CallbackData = new class'UICallbackData_StateObjectReference';
	CallbackData.ObjectRef = Unit.GetReference();
	DialogData.xUserData = CallbackData;
	DialogData.fnCallbackEx = ConditionSoldierDialogCallback;

	DialogData.eType = eDialog_Alert;
	DialogData.strTitle = m_strConditionSoldierDialogTitle;
	DialogData.strText = `XEXPAND.ExpandString(m_strConditionSoldierDialogText);
	DialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	DialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericNo;

	Movie.Pres.UIRaiseDialog(DialogData);
}

simulated function ConditionSoldierDialogCallback(Name eAction, UICallbackData xUserData)
{
	local UICallbackData_StateObjectReference CallbackData;
	local XComHQPresentationLayer HQPres;
	local UIChooseClass_ConditionSoldier ChooseClassScreen;	
		
	CallbackData = UICallbackData_StateObjectReference(xUserData);
	
	if (eAction == 'eUIAction_Accept')
	{				
		HQPres = `HQPRES;		

		if (HQPres.ScreenStack.IsNotInStack(class'UIChooseClass_ConditionSoldier'))
		{
			ChooseClassScreen = Spawn(class'UIChooseClass_ConditionSoldier', self);			
			ChooseClassScreen.m_UnitRef = CallbackData.ObjectRef;
			HQPres.ScreenStack.Push(ChooseClassScreen);
		}
	}
}

//==============================================================================

defaultproperties
{
	width = 370;
	height = 65;
}