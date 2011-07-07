// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
function SetAllCheckBoxes(FormName, FieldName, CheckValue)
{
	if(!document.forms[FormName])
		return;
	var objCheckBoxes = document.forms[FormName].elements[FieldName];
	if(!objCheckBoxes)
		return;
	var countCheckBoxes = objCheckBoxes.length;
	if(!countCheckBoxes)
		objCheckBoxes.checked = CheckValue;
	else
		// set the check value for all check boxes
		for(var i = 0; i < countCheckBoxes; i++)
			objCheckBoxes[i].checked = CheckValue;
}

function ToggleIndexingLock()
{
	document.forms['box_form'].elements['marked_for_indexing'].checked = document.forms['box_form'].elements['marked_for_indexing_locked'].checked;
	document.forms['box_form'].elements['marked_for_indexing'].disabled = document.forms['box_form'].elements['marked_for_indexing_locked'].checked;
}