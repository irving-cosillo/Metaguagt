trigger TriggerProductPrice on Product_Price__c (after insert, before update, after delete) {
    if (Trigger.isDelete){
        ClassTrigger.deletePrices(Trigger.old);
    } else if (Trigger.isInsert){
        ClassTrigger.addProductStock(Trigger.new);
    } else if (Trigger.isBefore && Trigger.isUpdate) {
        ClassTrigger.updateProductStock(Trigger.old);
    }
}