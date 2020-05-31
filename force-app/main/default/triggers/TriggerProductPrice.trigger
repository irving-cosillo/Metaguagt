trigger TriggerProductPrice on Product_Price__c (after insert, after update, after delete) {
    if (Trigger.isDelete){
        ClassTrigger.updateProductStock(Trigger.old, true);
    } else if (Trigger.isInsert){
        ClassTrigger.updateProductStock(Trigger.new, true);
    } else {
        ClassTrigger.updateProductStock(Trigger.new, false);
    }
}