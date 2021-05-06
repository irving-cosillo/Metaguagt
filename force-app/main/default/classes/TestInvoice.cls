@IsTest
public class TestInvoice {
    @IsTest
    static void getPurchaseOrderInfo(){
        Quote__c quote = TestSetup.createQuote();
        String purchaseOrderId = ClassPurchaseOrder.createPurchaseOrder(quote.Id, quote.Contact__c, null);
        Test.startTest();
        ClassInvoice.EntityInvoice purchaseOrderInfo = ClassInvoice.getPurchaseOrderInfo(purchaseOrderId);
        System.assertEquals(quote.Id, purchaseOrderInfo.quote.Id, 'Invalid quote retrieved.');

        ClassInvoice.EntityLegalInformation legalInfo = ClassInvoice.getClientLegalInformation('12345678', purchaseOrderInfo.companyInfo);
        System.assertEquals(true, String.isNotBlank(legalInfo.legalName), 'Legal info not retrieved.');
        
        String exceptionMsg = null;
        try {
            ClassInvoice.EntityInvoice purchaseOrderInfoInvalid = ClassInvoice.getPurchaseOrderInfo('Invalid Id retrieved.');
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
        String xml = '{total}{iva}{items}';

        Test.startTest();
        ClassInvoice.EntityInvoiceWrapper wrapper = ClassInvoice.getInvoiceWrapper(invoice, xml);
        System.assertEquals(true, String.isNotBlank(wrapper.xmlEncoded), 'Empty xmlEncoded response.');
        String invoiceId;
        String exMessage;
        try{
            invoiceId = ClassInvoice.insertInvoiceApex(wrapper.invoice, wrapper.purchaseOrder, wrapper.dispatchOrders);
        } catch(Exception ex){
            exMessage = ex.getMessage();
        } 
        System.assertEquals(true, String.isBlank(exMessage), 'Exception thrown: ' + exMessage);
        System.assertEquals(true, String.isNotBlank(invoiceId), 'Invoice not created.');

        ClassInvoice.cancelInvoiceApex(invoiceId,'Test Reasson');
        invoice = [SELECT Canceled__c, Cancellation_Reason__c FROM Invoice__c WHERE Id =: invoiceId];
        System.assertEquals(true, invoice.Canceled__c, 'Invoice not cancelled correctly.');
        System.assertEquals('Test Reasson', invoice.Cancellation_Reason__c, 'Incorrect cancel reasson retrieved.');
        ClassInvoice.EntityCanelInvoiceInformation response = ClassInvoice.getInvoiceInformation(invoiceId);
        System.assertEquals(invoiceId, response.invoice.Id, 'Incorrect invoice retrieved.');
        Test.stopTest();
    }

    @IsTest
    static void externalCalls(){
        Company_Information__mdt companyInfo = [
            SELECT
                Label,
                Legal_Name__c,
                NIT__c,
                Address__c,
                Invoice_Email__c,
                Infile_User__c,
                Infile_NIT__c,
                Infile_Sign_Key__c,
                Infile_Sign_Endpoint__c,
                Infile_Certification_Key__c,
                Infile_Certification_Endpoint__c,
                Infile_Anulation_Endpoint__c,
                Infile_NIT_Endpoint__c
            FROM Company_Information__mdt
            LIMIT 1
        ];

        ClassInvoice.EntitySignInvoiceResponse signInvoiceResponse = ClassInvoice.signInvoice('', companyInfo, true );
        System.assertEquals(true, signInvoiceResponse.resultado, 'Invalid result.');

        EntityInvoiceResponse processInvoiceResponse = ClassInvoice.processInvoice('', companyInfo, '', '', false);
        System.assertEquals(true, processInvoiceResponse.resultado, 'Invalid result.');
    }
}