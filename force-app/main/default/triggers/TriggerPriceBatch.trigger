trigger TriggerPriceBatch on Price_Batch__c (before insert, before update) {
    for(Price_Batch__c batch : trigger.new){
        batch.Taxes__c = batch.Taxes__c != NULL ? batch.Taxes__c : 0;
        batch.Dollar_Cost__c = batch.Dollar_Cost__c != NULL ? batch.Dollar_Cost__c : 0;
        batch.Internal_Shipping__c = batch.Internal_Shipping__c != NULL ? batch.Internal_Shipping__c : 0;
        batch.External_Shipping_GTQ__c = batch.External_Shipping_GTQ__c != NULL ? batch.External_Shipping_GTQ__c : 0;
        batch.External_Shipping_USD__c = batch.External_Shipping_USD__c != NULL ? batch.External_Shipping_USD__c : 0;
    }
}