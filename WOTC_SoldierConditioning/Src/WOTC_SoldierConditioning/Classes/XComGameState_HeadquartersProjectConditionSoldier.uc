class XComGameState_HeadquartersProjectConditionSoldier extends XComGameState_HeadquartersProjectTrainRookie config(Game);

var() ECharStatType ConditionStat;
var() X2AbilityTemplate AbilityTemplate; 
var string ExtraInfo;
var int AbilityPointsGranted, StatBonus;
var array<name> GrantedAbilities;

var localized string m_strAbilityPoints;
var localized string m_strAbilities;
var localized string m_strAbility;
var localized string m_strColorCS;

//---------------------------------------------------------------------------------------
function int CalculatePointsToTrain()
{
	return class'X2DownloadableContentInfo_WOTC_SoldierConditioning'.static.GetTrainingDays(XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ProjectFocus.ObjectID))) * 24;
}

//---------------------------------------------------------------------------------------
// Remove the project
function OnProjectCompleted()
{
	local HeadquartersOrderInputContext OrderInput;
	local XComHeadquartersCheatManager CheatMgr;	
	local int i;

	OrderInput.OrderType = eHeadquartersOrderType_TrainRookieCompleted;
	OrderInput.AcquireObjectReference = self.GetReference();

	class'XComGameStateContext_HeadquartersOrderCS'.static.IssueHeadquartersOrderCS(OrderInput);

	CheatMgr = XComHeadquartersCheatManager(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().CheatManager);
	if (CheatMgr == none || !CheatMgr.bGamesComDemo)
	{					
		for(i = 0; i < GrantedAbilities.Length; i++)
		{			
			if(i == 0) ExtraInfo = "+";
			ExtraInfo $= "<font color='#3ABD23'>" $class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(GrantedAbilities[i]).LocFriendlyName;			
			if (i == GrantedAbilities.Length - 1) ExtraInfo $= "</font>"; else ExtraInfo $= "</font>, ";
		}
		if(GrantedAbilities.Length > 0)
			if(GrantedAbilities.Length > 1) ExtraInfo @= m_strAbilities $"\n"; else ExtraInfo @= m_strAbility $"\n";

		ExtraInfo $= "+<font color='#3ABD23'>" $StatBonus $"</font>" @class'X2TacticalGameRulesetDataStructures'.default.m_aCharStatLabels[ConditionStat]
					@"\n+<font color='#3ABD23'>" $AbilityPointsGranted $"</font>" @m_strAbilityPoints;
		
		class'XComHQPresentationLayer_CS'.static.UICSTrainingComplete(ProjectFocus, AbilityTemplate, ExtraInfo, class'X2TacticalGameRulesetDataStructures'.default.m_aCharStatLabels[ConditionStat]);
	}
}

//---------------------------------------------------------------------------------------
DefaultProperties
{
}