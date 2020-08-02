@IsTest
public class TestInvoice {
    @IsTest
    static void getPurchaseOrderInfo(){
        Quote__c quote = TestSetup.createQuote();
        String purchaseOrderId = ClassPurchaseOrder.createPurchaseOrder(quote.Id, quote.Contact__c, null);
        Test.startTest();
        ClassInvoice.EntityInvoice purchaseOrderInfo = ClassInvoice.getPurchaseOrderInfo(purchaseOrderId);
        System.assertEquals(quote.Id, purchaseOrderInfo.quote.Id, 'Invalid quote retrieved.');

        String exceptionMsg = null;
        try {
            ClassInvoice.EntityInvoice purchaseOrderInfoInvalid = ClassInvoice.getPurchaseOrderInfo('Invalid Id');
        } catch (Exception ex){
            exceptionMsg = ex.getMessage();
        }

        System.assertNotEquals(null, exceptionMsg, 'Invalid purchase Id must throw an exception.');
        Test.stopTest();
    }

    @IsTest
    static void createInvoice(){
        Quote__c quote = TestSetup.createQuote();
        String purchaseOrderId = ClassPurchaseOrder.createPurchaseOrder(quote.Id, quote.Contact__c, null);
        List<Purchase_Order_Line__c> purchaseOrderLines = [SELECT Id FROM Purchase_Order_Line__c WHERE Purchase_Order__c =: purchaseOrderId];

        Dispatch_Order_Line__c dispatchOrderLine;
        List<Dispatch_Order_Line__c> dispatchOrderLines = new List<Dispatch_Order_Line__c>();
        for (Integer i = 0; i < purchaseOrderLines.size(); i++){
            dispatchOrderLine =  new Dispatch_Order_Line__c();
            dispatchOrderLine.Purchase_Order_Line__c = purchaseOrderLines[i].Id;
            dispatchOrderLine.Quantity__c = 9 + i;
            dispatchOrderLines.add(dispatchOrderLine);
        }
        String dispatchOrderId = ClassDispatchOrder.createDispatchOrder(purchaseOrderId, dispatchOrderLines);
        Invoice__c invoice = new Invoice__c();
        invoice.Date__c = Date.today();
        invoice.Currency_Code__c = 'GTQ';
        invoice.Category__c = 'Ordenes de Despacho';
        invoice.Purchase_Order__c = purchaseOrderId;
        invoice.Dispatch_Orders__c = dispatchOrderId;

        Test.startTest();
        ClassInvoice.createInvoice(invoice);
        Invoice__c expectedInvoice = [SELECT Id, Purchase_Order__c FROM Invoice__c LIMIT 1];
        System.assertEquals(purchaseOrderId, expectedInvoice.Purchase_Order__c, 'Invoice not generated correctly.');
        Test.stopTest();
    }
}
