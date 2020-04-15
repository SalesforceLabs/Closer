({
	init : function(component, event, helper) {
        location.href = 'mobilecontentguide://'
        $A.get("e.force:closeQuickAction").fire()
	}
})