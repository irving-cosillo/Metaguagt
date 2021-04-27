public with sharing class ClassDispatchOrder {
    @AuraEnabled
    public static Id createDispatchOrder(Id purchaseOrderId, List<Dispatch_Order_Line__c> dispatchOrderLines){
        Dispatch_Order__c dispatchOrder = new Dispatch_Order__c();
        dispatchOrder.Purchase_Order__c = purchaseOrderId;
        dispatchOrder.State__c = 'Pendiente de despacho';
        insert(dispatchOrder);

        for(Integer i = 0; i < dispatchOrderLines.size(); i++){
            dispatchOrderLines[i].Dispatch_Order__c = dispatchOrder.Id;
        }
        insert(dispatchOrderLines);

        List<Id> purchasOrderLinesId = new List<Id>();
        for(Integer i = 0; i < dispatchOrderLines.size(); i++){
            purchasOrderLinesId.add(dispatchOrderLines[i].Purchase_Order_Line__c);
        }

        Map<Id, Purchase_Order_Line__c> purchaseOrderLines = new Map<Id, Purchase_Order_Line__c>([
            SELECT Id, Dispatch_Pending_Quantity__c
            FROM Purchase_Order_Line__c
            WHERE Id IN : purchasOrderLinesId
        ]);

        String key;
        for(Integer i = 0; i < dispatchOrderLines.size(); i++){
            key = purchasOrderLinesId[i];
            purchaseOrderLines.get(key).Dispatch_Pending_Quantity__c += dispatchOrderLines[i].Quantity__c;
        }
        upsert(purchaseOrderLines.values());

        return dispatchOrder.Id;
    }

    @AuraEnabled
    public static void dispatchOrder(String dispatchOrderId){
        Dispatch_Order__c dispatchOrder = [SELECT Id, State__c, Purchase_Order__c FROM Dispatch_Order__c WHERE Id =: dispatchOrderId LIMIT 1];
        List<Dispatch_Order_Line__c> dispatchOrderLines = [SELECT Id, Quantity__c, Purchase_Order_Line__c FROM Dispatch_Order_Line__c WHERE Dispatch_Order__c =: dispatchOrder.Id];

        if(dispatchOrder.State__c == 'Despachada'){
            throw new AuraHandledException('La orden ya ha sido despachada.');
        }

        Purchase_Order__c purchaseOrder = [SELECT Id FROM Purchase_Order__c WHERE Id =: dispatchOrder.Purchase_Order__c LIMIT 1];
        Map<Id, Purchase_Order_Line__c> purchaseOrderLines = new Map<Id, Purchase_Order_Line__c>([
            SELECT Id, Quantity__c, Dispatched_Quantity__c, Dispatch_Pending_Quantity__c, Product_Id__c
            FROM Purchase_Order_Line__c
            WHERE Purchase_Order__c =: dispatchOrder.Purchase_Order__c
        ]);

        Decimal dispatchQuantity;
        String purchaseOrderLineId;
        Map<String, Decimal> productStock = new Map<String, Decimal>();
        for(Dispatch_Order_Line__c dispatchOrderLine : dispatchOrderLines ){
            dispatchQuantity = dispatchOrderLine.Quantity__c;
            purchaseOrderLineId = dispatchOrderLine.Purchase_Order_Line__c;
            productStock.put(purchaseOrderLines.get(purchaseOrderLineId).Product_Id__c, dispatchQuantity);
            purchaseOrderLines.get(purchaseOrderLineId).Dispatched_Quantity__c += dispatchQuantity;
            purchaseOrderLines.get(purchaseOrderLineId).Dispatch_Pending_Quantity__c -= dispatchQuantity;
        }

        Set<String> productsId = productStock.keySet();
        Map<Id, Product__c> products = new Map<Id, Product__c>([
            SELECT Stock__c
            FROM Product__c
            WHERE Id IN : productsId
        ]);

        for(String productId : productsId){
            if(products.get(productId).Stock__c < productStock.get(productId)){
                throw new AuraHandledException('No hay producto suficiente en bodega para ser despachado.');
            }
            products.get(productId).Stock__c -= productStock.get(productId);
        }

        Boolean completed = true;
        for(Purchase_Order_Line__c purchaseOrderLine : purchaseOrderLines.values()){
            if(purchaseOrderLine.Quantity__c != purchaseOrderLine.Dispatched_Quantity__c){
                completed = false;
            }
        }

        dispatchOrder.State__c = 'Despachada';
        purchaseOrder.Dispatch_Status__c = completed ? 'Completado' : 'Parcialmente';

        update(purchaseOrderLines.values());
        update(products.values());
        update(dispatchOrder);
        update(purchaseOrder);
    }

    @AuraEnabled
    public static List<Dispatch_Order_Line__c> getDispatchOrderLines(String dispatchOrderId){
        return [
            SELECT Id, Quantity__c, Stock__c, Product_Name__c, Product_Description__c
            FROM Dispatch_Order_Line__c
            WHERE Dispatch_Order__c =: dispatchOrderId
        ];
    }

    @AuraEnabled
    public static void cancelDispatchOrder(String dispatchOrderId){
        Dispatch_Order__c dispatchOrder = [SELECT Id, State__c, Invoice__c FROM Dispatch_Order__c WHERE Id =: dispatchOrderId];
        List<Dispatch_Order_Line__c> dispatchOrderLines = [SELECT Id FROM Dispatch_Order_Line__c WHERE Dispatch_Order__c =: dispatchOrderId];
        
        if (dispatchOrder.State__c == 'Despachada'){
            throw new AuraHandledException('La orden de despacho no puede ser anulada porque ya ha sido despachada.');
        } else if (String.isNotBlank(dispatchOrder.Invoice__c)){
            throw new AuraHandledException('La orden de despacho no puede ser anulada porque ya fue facturada.');
        } else {
            if(dispatchOrderLines.size() > 0){
                delete dispatchOrderLines;
            }
            delete dispatchOrder;
        }
    }
}