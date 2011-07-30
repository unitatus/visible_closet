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

function removeElement(parentDiv, childDiv)
{
     if (childDiv == parentDiv) {
          alert("The parent div cannot be removed.");
     }
     else if (document.getElementById(childDiv)) {     
          var child = document.getElementById(childDiv);
          var parent = document.getElementById(parentDiv);

          parent.removeChild(child);
     }
     else {
          alert("Child div has already been removed or does not exist.");
          return false;
     }
}

function utcToLocal(value) {
	var a = /^(\d{4})-(\d{2})-(\d{2})\s(\d{2}):(\d{2}):(\d{2})\sUTC$/.exec(value);

    if (a) {
		parsed_date = new Date(Date.UTC(+a[1], +a[2] - 1, +a[3], +a[4], +a[5], +a[6]));
        return parsed_date.toString("MMMM dd, yyyy hh:mm tt ");
    }

    return null;
}

// The following is to slow down image change on stored_item image review
$(document).ready(function(){
	// Fades store/portfolio link overlays
	
	jQuery('.thumbnails .post-thumbnail').hover( function () {
		jQuery(this).find('ul').css('display','inline').animate({opacity: 0}, 0).stop().animate({opacity: 1}, 300);
	}, function () {
		jQuery(this).find('ul').stop().animate({opacity: 0}, 300);
	});
	
    $('.browse-box .browse-box-menu').hover(
          function () {
            $($(this)).find("div").show();
          }, 
          function () {
            $($(this)).find("div").hide();
          }
    );
    
    $('.increment-up').click(function(){
        oldVal = parseInt($($(this)).parent().find("input").attr('value'));
        $($(this)).parent().find("input").attr('value',oldVal+1)
    });
    
    $('.increment-down').click(function(){
        oldVal = parseInt($($(this)).parent().find("input").attr('value'));
        if(oldVal>0){
        $($(this)).parent().find("input").attr('value',oldVal-1)
        }
    });
    
    $('#inventory-menu-rightarrow').click(function(){
        if($('#inventory-menu-rightarrow').hasClass('enabled')){
            $('#inventory-menu-rightarrow').removeClass('enabled');
            boxCount = $("#inventory-boxcanvas").find(".inventory-boxdisplay-box").length;
            curPos = $("#inventory-boxcanvas").position().left;
            boxSize = 120;
            if(curPos > 0-((boxCount*boxSize)-(5*boxSize))){
                $("#inventory-boxcanvas").animate({
                    left: '-='+boxSize
                  }, 1000, function() {
                    $('#inventory-menu-rightarrow').addClass('enabled');
                    $('#inventory-menu-leftarrow').removeClass('disabled');
                    boxCount = $("#inventory-boxcanvas").find(".inventory-boxdisplay-box").length;
                    curPos = $("#inventory-boxcanvas").position().left;
                    if(curPos <= 0-((boxCount*boxSize)-(5*boxSize))){
                        $('#inventory-menu-rightarrow').addClass('disabled');
                    }
                  });
            }else{
                $('#inventory-menu-rightarrow').addClass('enabled');
            }
        }
    });
    
    $('#inventory-menu-leftarrow').click(function(){
        if($('#inventory-menu-leftarrow').hasClass('enabled')){
            $('#inventory-menu-leftarrow').removeClass('enabled');
            boxCount = $("#inventory-boxcanvas").find(".inventory-boxdisplay-box").length;
            curPos = $("#inventory-boxcanvas").position().left;
            boxSize = 120;
            if(curPos < 0){
                $("#inventory-boxcanvas").animate({
                    left: '+='+boxSize
                  }, 1000, function() {
                    $('#inventory-menu-leftarrow').addClass('enabled');
                    $('#inventory-menu-rightarrow').removeClass('disabled');
                    boxCount = $("#inventory-boxcanvas").find(".inventory-boxdisplay-box").length;
                    curPos = $("#inventory-boxcanvas").position().left;
                    if(curPos >= 0){
                        $('#inventory-menu-leftarrow').addClass('disabled');
                    }
                  });
            }else{
                $('#inventory-menu-leftarrow').addClass('enabled');
            }
        }
    });
    
    boxCount = $("#inventory-boxcanvas").find(".inventory-boxdisplay-box").length;
    boxSize = 120;
    widthCalc = boxSize * boxCount;
    $("#inventory-boxcanvas").css('width',widthCalc);
    whichActive = $('#inventory-boxdisplay').find(".activebox").index();
    offsetMax = boxCount-5
    if(offsetMax<0){
        offsetMax=0;
    }
    
    if (whichActive > offsetMax){
        offsetCalc = offsetMax*boxSize;
    }else{
        offsetCalc = whichActive*boxSize;
    }
    
    $("#inventory-boxcanvas").animate({
        left: '-='+offsetCalc
      }, 1000, function() {
        $('#inventory-menu-leftarrow').addClass('enabled');
        $('#inventory-menu-rightarrow').addClass('enabled');
        curPos = $("#inventory-boxcanvas").position().left;
        if(curPos != 0){
            $('#inventory-menu-leftarrow').removeClass('disabled');
        }
        if(curPos == 0-((boxCount*boxSize)-(5*boxSize))){
            $('#inventory-menu-rightarrow').addClass('disabled');
        }
        if(boxCount<=5){
            $('#inventory-menu-rightarrow').addClass('disabled');
        }
      });

});