class UIAlert_ConditionSoldier extends UIAlert;

var localized string m_strContinueCSTraining;
var localized string m_strBonusCS;

simulated function BuildAlert()
{
	BindLibraryItem();

	switch( eAlertName )
	{
	case 'eAlert_TrainingComplete':
		BuildConditionTrainingCompleteAlert(m_strTrainingCompleteLabel);
		break;

	default:
		AddBG(MakeRect(0, 0, 1000, 500), eUIState_Normal).SetAlpha(0.75f);
		break;
	}

	RefreshNavigation();

}

simulated function Name GetLibraryID()
{
	//This gets the Flash library name to load in a panel. No name means no library asset yet. 
	switch ( eAlertName )
	{	
	case 'eAlert_TrainingComplete': return 'Alert_TrainingComplete';
	default:
		return '';
	}
}

simulated function BuildConditionTrainingCompleteAlert(string TitleLabel)
{
	local XComGameState_Unit UnitState;
	local X2AbilityTemplate TrainedAbilityTemplate;	
	local X2AbilityTemplateManager AbilityTemplateManager;
	local XGParamTag kTag;
	local XComGameState_ResistanceFaction FactionState;
	local string AbilityIcon, AbilityName, AbilityDescription, ClassIcon, ClassName, RankName, ExtraInfo;	
	
	if( LibraryPanel == none )
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertName: " $ eAlertName);
		return;
	}

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'UnitRef')));
	// Start Issue #106
	ClassName = Caps(UnitState.GetSoldierClassDisplayName());
	ClassIcon = UnitState.GetSoldierClassIcon();
	// End Issue #106
	RankName = Caps(UnitState.GetSoldierRankName()); // Issue #408
	
	FactionState = UnitState.GetResistanceFaction();

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	kTag.StrValue0 = "";

	ExtraInfo = class'X2StrategyGameRulesetDataStructures'.static.GetDynamicStringProperty(DisplayPropertySet, 'ExtraInfo');	
	`LOG("ExtraInfo:" @ExtraInfo, class'X2DownloadableContentInfo_WOTC_SoldierConditioning'.default.bEnableLog, 'WOTC_SolderConditioning');	

	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	TrainedAbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicNameProperty(DisplayPropertySet, 'AbilityTemplate'));	
	
	AbilityIcon = TrainedAbilityTemplate.IconImage;
	AbilityDescription = ExtraInfo;	
	AbilityName =  class'X2StrategyGameRulesetDataStructures'.static.GetDynamicStringProperty(DisplayPropertySet, 'Stat') @class'UIChooseClass_ConditionSoldier'.default.m_strStatTitle;

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(TitleLabel);
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.QueueString(ClassIcon);
	LibraryPanel.MC.QueueString(RankName);
	LibraryPanel.MC.QueueString(UnitState.GetName(eNameType_FullNick));
	LibraryPanel.MC.QueueString(ClassName);
	LibraryPanel.MC.QueueString(AbilityIcon);		 // Ability Icon
	LibraryPanel.MC.QueueString(m_strBonusCS);		 // From localization
	LibraryPanel.MC.QueueString(AbilityName); 		 // Training description as per UIChooseClass_ConditionSoldier
	LibraryPanel.MC.QueueString(AbilityDescription); // Extra Info from XComGameState_HeadquartersProjectConditionSoldier
	LibraryPanel.MC.QueueString(m_strCarryOn);	
	LibraryPanel.MC.QueueString(m_strContinueCSTraining);
	LibraryPanel.MC.EndOp();
	GetOrStartWaitingForStaffImage();

	//Set icons before hiding the button.
	Button1.SetGamepadIcon(class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_X_SQUARE);
	Button2.SetGamepadIcon(class'UIUtilities_Input'.static.GetAdvanceButtonIcon());

	if (FactionState != none)
		SetFactionIcon(FactionState.GetFactionIcon());
}