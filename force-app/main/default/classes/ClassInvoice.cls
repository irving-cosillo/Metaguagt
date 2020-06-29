public with sharing class ClassInvoice {
    @AuraEnabled
    public static EntityInvoice getPurchaseOrderInfo(String purchaseOrderId){
        List<Purchase_Order__c> purchaseOrderList = [
            SELECT
                Order_Id__c,
                Account__c,
                Quote__c
            FROM Purchase_Order__c
            WHERE Id =: purchaseOrderId
            LIMIT 1
        ];

        if(purchaseOrderList.size() <= 0){
            throw new AuraHandledException('Error: por favor contactar al administrador del sistema.');
        }

        Purchase_Order__c purchaseOrder = purchaseOrderList[0];
        System.debug(purchaseOrder);
        Quote__c quote = [SELECT Credit__c, Payment__c FROM Quote__c WHERE Id =: purchaseOrder.Quote__c LIMIT 1];
        System.debug(quote);
        Map<Id, Dispatch_Order__c> dispatchOrdersMap = new Map<Id, Dispatch_Order__c>([
            SELECT
                Id,
                Name
            FROM Dispatch_Order__c
            WHERE Purchase_Order__c =: purchaseOrderId
            AND Invoice__c = null
        ]);

        Set<Id> dispatchOrdersId = dispatchOrdersMap.keySet();
        List<Dispatch_Order__c> dispatchOrders = dispatchOrdersMap.values();
        System.debug(dispatchOrders);
        List<Dispatch_Order_Line__c> dispatchOrderLines = [
            SELECT
                Product_Name__c,
                //product all name and description formula
                Quantity__c
            FROM Dispatch_Order_Line__c
            WHERE Dispatch_Order__c IN  :dispatchOrdersId
        ];
        System.debug(dispatchOrderLines);
        
        EntityInvoice invoice = new EntityInvoice();
        invoice.quote = quote;
        invoice.purchaseOrder = purchaseOrder;
        invoice.dispatchOrders = dispatchOrders;
        invoice.dispatchOrderLines = dispatchOrderLines;
        System.debug(invoice);
        return invoice;
    }
}
