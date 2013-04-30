class ItemShovel: ItemCore
{
	scope=2;
	displayName="Shovel";
	model="\z\addons\dayz_communityassets\models\shovel.p3d";
	picture="\z\addons\dayz_communityassets\pictures\equip_shovel_ca.paa";
	descriptionShort="Shovel";
	stashtype = "StashSmall";
	class ItemActions
	{
		class Use
		{
			text="Create Stash";
			script="spawn player_createstash;";
		};
	};
};