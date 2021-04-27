@IsTest
public class TestDispatchOrder {
    @IsTest
    static void createDispatchOrder(){
        Quote__c quote = TestSetup.createQuote();
        String purchaseOrderId = ClassPurchaseOrder.createPurchaseOrder(quote.Id, quote.Contact__c, null);
        List<Purchase_Order_Line__c> purchaseOrderLines = [SELECT Id FROM Purchase_Order_Line__c WHERE Purchase_Order__c =: purchaseOrderId];

        Dispatch_Order_Line__c dispatchOrderLine;
        List<Dispatch_Order_Line__c> dispatchOrderLines = new List<Dispatch_Order_Line__c>();
        for (Integer i = 0; i < purchaseOrderLines.size(); i++){
            dispatchOrderLine =  new Dispatch_Order_Line__c();
            dispatchOrderLine.Purchase_Order_Line__c = purchaseOrderLines[i].Id;
            dispatchOrderLine.Quantity__c = 5 + i;
            dispatchOrderLines.add(dispatchOrderLine);
        }

        Test.startTest();
        String dispatchOrderId = ClassDispatchOrder.createDispatchOrder(purchaseOrderId, dispatchOrderLines);
        Dispatch_Order__c dispatchOrder = [SELECT State__c FROM Dispatch_Order__c WHERE Id =: dispatchOrderId];
        System.assertEquals('Pendiente de despacho', dispatchOrder.State__c, 'Dispatch Order not found or incorrect state was set');

        String exMessage = '';
        try{
            ClassDispatchOrder.cancelDispatchOrder(dispatchOrderId);
        } catch (Exception ex){
            exMessage = ex.getMessage();
        }

        System.assertEquals('', exMessage, 'Dispatch Order was not cancelled correctly. ' + exMessage);
        Test.stopTest();
    }

    @IsTest
    static void dispatchOrder(){
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

        Test.startTest();
        ClassDispatchOrder.dispatchOrder(dispatchOrderId);
        Purchase_Order__c purchaseOrder = [SELECT Dispatch_Status__c FROM Purchase_Order__c WHERE Id =: purchaseOrderId];
        Dispatch_Order__c dispatchOrder = [SELECT State__c FROM Dispatch_Order__c WHERE Purchase_Order__c =: purchaseOrderId];
        System.assertEquals('Parcialmente', purchaseOrder.Dispatch_Status__c, 'Incorrect dispatch status from purchase order.');
        System.assertEquals('Despachada', dispatchOrder.State__c, 'Incorrect dispatch status from dispatch order.');

        //-- Second part of the test, check if the order was completly dispatched
        Dispatch_Order_Line__c dispatchOrderLine2;
        List<Dispatch_Order_Line__c> dispatchOrderLines2 = new List<Dispatch_Order_Line__c>();
        for (Integer i = 0; i < purchaseOrderLines.size(); i++){
            dispatchOrderLine2 =  new Dispatch_Order_Line__c();
            dispatchOrderLine2.Purchase_Order_Line__c = purchaseOrderLines[i].Id;
            dispatchOrderLine2.Quantity__c = 1;
            dispatchOrderLines2.add(dispatchOrderLine2);
        }
        String dispatchOrderId2 = ClassDispatchOrder.createDispatchOrder(purchaseOrderId, dispatchOrderLines2);

        ClassDispatchOrder.dispatchOrder(dispatchOrderId2);
        purchaseOrder = [SELECT Dispatch_Status__c FROM Purchase_Order__c WHERE Id =: purchaseOrderId];
        System.assertEquals('Completado', purchaseOrder.Dispatch_Status__c, 'Incorrect dispatch final status from purchase order.');
        
        String exMessage = '';
        try{
            ClassDispatchOrder.cancelDispatchOrder(dispatchOrder.Id);
        } catch (Exception ex){
            exMessage = ex.getMessage();
        }

        System.assertNotEquals('', exMessage, 'Dispatch Order did not throw the invoice exception.');
        Test.stopTest();
    }

    @IsTest
    static void getDispatchOrderLines(){
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

        Test.startTest();
        List<Dispatch_Order_Line__c> expectedDispatchOrderLines = ClassDispatchOrder.getDispatchOrderLines(dispatchOrderId);
        System.assertEquals(3, expectedDispatchOrderLines.size(), 'Incorrect number of dispatch order lines retrieved.');
        Test.stopTest();
    }
}