({
    cancel : function(component, event, helper) {
        $A.get('e.force:refreshView').fire();
        $A.get("e.force:closeQuickAction").fire();
    }
})