public with sharing class ClassDispatchOrder {
    @AuraEnabled
    public static Id createDispatchOrder(Id purchaseOrderId, List<Dispatch_Order_Line__c> dispatchOrderLines){
        try {    
            Dispatch_Order__c dispatchOrder = new Dispatch_Order__c();
            dispatchOrder.Purchase_Order__c = purchaseOrderId;
            insert(dispatchOrder);
        
            List<Id> purchasOrderLinesId = new List<Id>();
            for(Integer i = 0; i < dispatchOrderLines.size(); i++){
                dispatchOrderLines[i].Dispatch_Order__c = dispatchOrder.Id;
                purchasOrderLinesId.add(dispatchOrderLines[i].Purchase_Order_Line__c);
            }
            insert(dispatchOrderLines);

            Map<Id, Purchase_Order_Line__c> purchaseOrderLines = new Map<Id, Purchase_Order_Line__c>([
                SELECT Id, Dispatched_Quantity__c 
                FROM Purchase_Order_Line__c         
                WHERE Id IN : purchasOrderLinesId
            ]);

            String key;
            for(Integer i = 0; i < dispatchOrderLines.size(); i++){
                key = purchasOrderLinesId[i];
                purchaseOrderLines.get(key).Dispatched_Quantity__c += dispatchOrderLines[i].Quantity__c;
            }
            upsert(purchaseOrderLines.values());

            return dispatchOrder.Id;

        } catch(Exception e){
            throw new AuraHandledException('La orden de despacho no logró ser creada, por favor contactar al administrador del sistema.');
        }
    }
}
