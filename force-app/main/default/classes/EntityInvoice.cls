public with sharing class EntityInvoice {
    @AuraEnabled
    public Quote__c quote {get; set;}
    @AuraEnabled
    public Purchase_Order__c purchaseOrder {get; set;}
    @AuraEnabled
    public List<Dispatch_Order__c> dispatchOrders {get; set;}
    @AuraEnabled
    public List<Dispatch_Order_Line__c> dispatchOrderLines {get; set;}
}
