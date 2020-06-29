public with sharing class ClassPurchaseOrder {

    @AuraEnabled
    public static Id createPurchaseOrder(String quoteId, String contactId, String orderId){
        Quote__c quote;
        List<Quote__c> quotes = [SELECT Contact__c, Account__c, Delivery_Address__c, Converted__c
                          FROM Quote__c
                          WHERE Id =: quoteId
                          LIMIT 1];

        if(quotes == null || quotes.size() <= 0){
            throw new AuraHandledException('No se encontro ninguna Cotización.');
        } else {
            quote = quotes[0];
        }

        quote.Converted__c = true;
        update(quote);

        Purchase_Order__c purchaseOrder = new Purchase_Order__c();
        purchaseOrder.Quote__c = quoteId;
        purchaseOrder.Contact__c = quote.Contact__c;
        purchaseOrder.Account__c = quote.Account__c;
        purchaseOrder.Delivery_Address__c = quote.Delivery_Address__c;
        purchaseOrder.Authorization_Contact__c = contactId;
        purchaseOrder.Order_Id__c = orderId;
        purchaseOrder.Invoice_Status__c = 'Pendiente';
        purchaseOrder.Dispatch_Status__c = 'Pendiente';
        insert(purchaseOrder);

        List<Quote_Line__c> quoteLines = [SELECT Id
                                          FROM Quote_Line__c
                                          WHERE Quote__c =: quoteId
                                          AND Type__c != 'Father'
                                          ORDER BY Index__c ASC];

        List<Purchase_Order_Line__c> purchaseOrderLines = new List<Purchase_Order_Line__c>();
        Purchase_Order_Line__c purchaseOrderLine;

        for(Quote_Line__c quoteLine : quoteLines){
            purchaseOrderLine = new Purchase_Order_Line__c();
            purchaseOrderLine.Purchase_Order__c = purchaseOrder.Id;
            purchaseOrderLine.Quote_Line__c = quoteLine.Id;
            purchaseOrderLine.Dispatched_Quantity__c = 0;
            purchaseOrderLine.Dispatch_Pending_Quantity__c = 0;
            purchaseOrderLines.add(purchaseOrderLine);
        }
        insert(purchaseOrderLines);
        return purchaseOrder.Id;
    }

    @AuraEnabled
    public static List<Purchase_Order_Line__c> getPurchaseOrderLines(String purchaseOrderId){
        return [SELECT  Id,
                        Product__c,
                        Product_Name__c,
                        Quantity__c,
                        Dispatched_Quantity__c,
                        Dispatch_Pending_Quantity__c,
                        Delivery_Time__c,
                        Stock__c
                FROM Purchase_Order_Line__c
                WHERE Purchase_Order__c =: purchaseOrderId];
    }
}