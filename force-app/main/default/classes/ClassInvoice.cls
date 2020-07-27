public with sharing class ClassInvoice {
    @AuraEnabled
    public static ClassInvoice.EntityInvoice getPurchaseOrderInfo(String purchaseOrderId){
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
        Quote__c quote = [SELECT Credit__c, Payment__c FROM Quote__c WHERE Id =: purchaseOrder.Quote__c LIMIT 1];
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
        List<Dispatch_Order_Line__c> dispatchOrderLines = [
            SELECT
                Product_Name__c,
                //product all name and description formula
                Quantity__c
            FROM Dispatch_Order_Line__c
            WHERE Dispatch_Order__c IN  :dispatchOrdersId
        ];
        Company_Information__mdt company = [SELECT Invoice_Email__c FROM Company_Information__mdt LIMIT 1];

        ClassInvoice.EntityInvoice invoice = new ClassInvoice.EntityInvoice();
        invoice.quote = quote;
        invoice.purchaseOrder = purchaseOrder;
        invoice.dispatchOrders = dispatchOrders;
        invoice.dispatchOrderLines = dispatchOrderLines;
        invoice.companyEmail = company.Invoice_Email__c;
        return invoice;
    }

    @AuraEnabled
    public static void createInvoice(Invoice__c invoice){
        Purchase_Order__c purchaseOrder = [SELECT Id, Invoice_Status__c, Currency_Code__c, Total__c FROM Purchase_Order__c WHERE Id =: invoice.Purchase_Order__c LIMIT 1];
        invoice.Currency_Code__c = purchaseOrder.Currency_Code__c;

        List<Dispatch_Order__c> dispatchOrders = new List<Dispatch_Order__c> ();
        if (invoice.Category__c == 'Ordenes de Despacho' && !String.isEmpty(invoice.Dispatch_Orders__c)){
            List<String> dispatchOrdersId = invoice.Dispatch_Orders__c.remove('"').remove('[').remove(']').split(',');
            dispatchOrders = [
                SELECT Id, State__c, Purchase_Order__c
                FROM Dispatch_Order__c
                WHERE Id IN : dispatchOrdersId
            ];
            List<Dispatch_Order_Line__c> dispatchOrderLines = [
                SELECT Id, Quantity__c, Purchase_Order_Line__c, Purchase_Order_Line__r.Quote_Line__r.Product__c
                FROM Dispatch_Order_Line__c
                WHERE Dispatch_Order__c IN : dispatchOrders
            ];
            Map<String,InvoiceLine> invoiceDescriptionMap = new Map<String,InvoiceLine>();
            InvoiceLine line;
            String productId ;
            //Repeated lines sum their quantities
            for (Dispatch_Order_Line__c dispatchOrderLine : dispatchOrderLines){
                productId = dispatchOrderLine.Purchase_Order_Line__r.Quote_Line__r.Product__c;
                if (invoiceDescriptionMap.get(productId) == null) {
                    line = new InvoiceLine();
                    line.productId = productId;
                    line.quantity = dispatchOrderLine.Quantity__c;
                    invoiceDescriptionMap.put(productId, line);
                } else {
                    invoiceDescriptionMap.get(productId).quantity += dispatchOrderLine.Quantity__c;
                }
            }

            Set<String> productsId = invoiceDescriptionMap.keySet();
            List<Product__c> products = [
                SELECT Id, Price_USD__c, Price_GTQ__c, Name, Description__c
                FROM Product__c
                WHERE Id IN : productsId
            ];

            Double price = 0;
            Double amount = 0;
            Double quantity = 0;
            invoice.Description__c = '';
            for (Product__c product: products) {
                invoiceDescriptionMap.get(product.Id).code = product.Name;
                invoiceDescriptionMap.get(product.Id).description = product.Description__c;
                quantity = invoiceDescriptionMap.get(product.Id).quantity;

                price = purchaseOrder.Currency_Code__c == 'GTQ' ? product.Price_GTQ__c : product.Price_GTQ__c;
                invoiceDescriptionMap.get(product.Id).price = price;
                amount += quantity * price;

                invoice.Description__c += product.Name + ' | ' +  quantity + ' | ' + purchaseOrder.Currency_Code__c + price + ' \r\n';
            }
            invoice.Description__c +=  'Total: ' + purchaseOrder.Currency_Code__c + amount;
            invoice.Amount__c = amount;
        }
        insert invoice;

        if (dispatchOrders.size() > 0) {
            for(Dispatch_Order__c dispatchOrder : dispatchOrders){
                dispatchOrder.Invoice__c = invoice.Id;
            }
            update dispatchOrders;
        }

        List<Invoice__c> invoices = [SELECT Amount__c FROM Invoice__c WHERE Purchase_Order__c =: purchaseOrder.Id];
        Double paidAmount = 0;
        for (Invoice__c paidInvoice : invoices){
            paidAmount += paidInvoice.Amount__c;
        }

        if (paidAmount <= 0){
            purchaseOrder.Invoice_Status__c = 'Pendiente';
        } else if (paidAmount < purchaseOrder.Total__c){
            purchaseOrder.Invoice_Status__c = 'Parcialmente';
        } else if (paidAmount == purchaseOrder.Total__c){
            purchaseOrder.Invoice_Status__c = 'Completado';
        } else {
            throw new AuraHandledException('El monto excede el total de la orden de compra.');
        }
        update purchaseOrder;
    }

    public class InvoiceLine{
        public String code {get; set;}
        public String productId {get; set;}
        public String description {get; set;}
        public Double quantity {get; set;}
        public Double price {get; set;}
    }

    public class EntityInvoice {
        @AuraEnabled
        public Quote__c quote {get; set;}
        @AuraEnabled
        public Purchase_Order__c purchaseOrder {get; set;}
        @AuraEnabled
        public List<Dispatch_Order__c> dispatchOrders {get; set;}
        @AuraEnabled
        public List<Dispatch_Order_Line__c> dispatchOrderLines {get; set;}
        @AuraEnabled
        public String companyEmail {get; set;}
    }
}