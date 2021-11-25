class XComHQPresentationLayer_CS extends Object abstract;

static function UICSTrainingComplete(StateObjectReference UnitRef, X2AbilityTemplate AbilityTemplate, string ExtraInfo, string Stat)
{
	local DynamicPropertySet PropertySet;

	BuildCSUIAlert(PropertySet, 'eAlert_TrainingComplete', CSTrainingCompleteCB, '', "Geoscape_CrewMemberLevelledUp", true);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'UnitRef', UnitRef.ObjectID);
    class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'AbilityTemplate', AbilityTemplate.DataName);
    class'X2StrategyGameRulesetDataStructures'.static.AddDynamicStringProperty(PropertySet, 'ExtraInfo', ExtraInfo);  
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicStringProperty(PropertySet, 'Stat', Stat);    
	class'XComPresentationLayerBase'.static.QueueDynamicPopup(PropertySet);
}

static function BuildCSUIAlert(
	out DynamicPropertySet PropertySet, 
	Name AlertName, 
	delegate<X2StrategyGameRulesetDataStructures.AlertCallback> CallbackFunction, 
	Name EventToTrigger, 
	string SoundToPlay,
	bool bImmediateDisplay = true)
{	
    class'X2StrategyGameRulesetDataStructures'.static.BuildDynamicPropertySet(PropertySet, 'UIAlert_ConditionSoldier', AlertName, CallbackFunction, bImmediateDisplay, true, true, false);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'EventToTrigger', EventToTrigger);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicStringProperty(PropertySet, 'SoundToPlay', SoundToPlay);
}

simulated function CSTrainingCompleteCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;
	
    `LOG(eAction, class'X2DownloadableContentInfo_WOTC_SoldierConditioning'.default.bEnableLog, 'WOTC_SolderConditioning');
	if( eAction == 'eUIAction_Accept' || eAction == 'eUIAction_Cancel' )
	{
		// Flag the new class popup as having been seen
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Unit Promotion Callback");
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit',
																	  class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(AlertData, 'UnitRef')));
		UnitState.bNeedsNewClassPopup = false;		
		`GAMERULES.SubmitGameState(NewGameState);

        if( eAction == 'eUIAction_Cancel' )
        {
            GoToTrainingCenter();
        }
	}
}

simulated function GoToTrainingCenter()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;
	
	if (`GAME.GetGeoscape().IsScanning())		
		`HQPRES.StrategyMap2D.ToggleScan();

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	FacilityState = XComHQ.GetFacilityByName('RecoveryCenter');
	FacilityState.GetMyTemplate().SelectFacilityFn(FacilityState.GetReference(), true);
}