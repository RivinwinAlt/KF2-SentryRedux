// Just a class to hold Category data for CategoryList, would have used a struct but we want to be able to pass the objects by pointer

Class KFGUI_Category extends Object;

var ST_GUIController Owner;
var KFGUI_Base ParentComponent; // Parent component if any.

var name CategoryID; // Used to identify which category to add a component to
var string CategoryTitle;
var bool bExpanded, LengthChangeFlag;
var int NumColumns; // Each category can have its own number of columns
var KFGUI_CategoryButton HeaderComponent; // Used to expand and collapse category, shows category name
var array<KFGUI_Base> Components;
var class<KFGUI_CategoryButton> DefaultHeaderClass;

function InitMenu()
{
	if(HeaderComponent == none) // HeaderComponent can be instantiated by calling class to change header class
		HeaderComponent = new(Self) DefaultHeaderClass;
	HeaderComponent.SetCategoryName(CategoryTitle);
	HeaderComponent.ParentComponent = ParentComponent;
	HeaderComponent.ParentCategory = Self;
	HeaderComponent.Owner = Owner;
	HeaderComponent.InitMenu();
}

function KFGUI_Base AddComponent(class<KFGUI_Base> ItemClass)
{
	local KFGUI_Base NewComp;

	NewComp = new(Self) ItemClass;
	NewComp.Owner = Owner;
	NewComp.ParentComponent = ParentComponent;
	//NewComp.InitMenu(); breaks compatability here, must call later wherever the category is being set up

	Components.AddItem(NewComp);
	
	return NewComp;
}

function LengthChanged()
{
	LengthChangeFlag = true;
}

function int GetLength()
{
	local int i;

	LengthChangeFlag = false;
	if(bExpanded)
	{
		i = Components.Length / NumColumns;
		if(Components.Length % NumColumns > 0)
			++i;
		return i;
	}
	else
	{
		return 0;
	}
}

defaultproperties
{
	DefaultHeaderClass = class'KFGUI_CategoryButton'
	LengthChangeFlag = true
}