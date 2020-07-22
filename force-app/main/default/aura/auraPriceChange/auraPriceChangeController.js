({
    success : function(component, event, helper) {
        $A.get('e.force:refreshView').fire();
        $A.get("e.force:closeQuickAction").fire();

        var resultsToast = $A.get("e.force:showToast");
        resultsToast.setParams({
            "title": "",
            "message": "Precio agregado con éxito.",
            "type" : "success"
        });
        resultsToast.fire();  
    },

    cancel : function(component, event, helper) {
        $A.get('e.force:refreshView').fire();
        $A.get("e.force:closeQuickAction").fire();
    }
})