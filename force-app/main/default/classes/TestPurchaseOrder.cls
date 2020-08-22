@IsTest
public class TestPurchaseOrder {
    @IsTest
    static void createPurchaseOrder(){
        Quote__c quote = TestSetup.createQuote();
        Test.startTest();
        String purchaseOrderId = ClassPurchaseOrder.createPurchaseOrder(quote.Id, quote.Contact__c, 'Test123');
        Purchase_Order__c purchaseOrder = [SELECT Quote__c FROM Purchase_Order__c WHERE Id =: purchaseOrderId];
        System.assertEquals(quote.Id, purchaseOrder.Quote__c, 'Purchase Order not found');

        String exceptionMsg = null;
        try {
            String purchaseOrderNull = ClassPurchaseOrder.createPurchaseOrder('Null Id', quote.Contact__c, '');
        } catch (Exception ex){
            exceptionMsg = ex.getMessage();
        }
        System.assertNotEquals(null, exceptionMsg, 'Incorrect excpetion message or not exception thrown.');
        Test.stopTest();
    }

    @IsTest
    static void getPurchaseOrderLines(){
        Quote__c quote = TestSetup.createQuote();
        String purchaseOrderId = ClassPurchaseOrder.createPurchaseOrder(quote.Id, quote.Contact__c, 'Test123');

        Test.startTest();
        List<Purchase_Order_Line__c> purcharseOrderLines = ClassPurchaseOrder.getPurchaseOrderLines(purchaseOrderId);
        System.assertEquals(3, purcharseOrderLines.size(), 'Invalid amount of purchase order lines.');
        Test.stopTest();
    }
}