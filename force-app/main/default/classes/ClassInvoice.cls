public with sharing class ClassInvoice {
    @AuraEnabled
    public static ClassInvoice.EntityInvoice getPurchaseOrderInfo(String purchaseOrderId){
        List<Purchase_Order__c> purchaseOrderList = [
            SELECT
                Order_Id__c,
                Account__c,
                Account__r.NIT__c,
                Quote__c,
                Quote__r.Sales_User__c,
                Quote__r.Credit__c,
                Currency_Code__c
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
        Company_Information__mdt company = [
            SELECT
                Label,
                Legal_Name__c,
                NIT__c,
                Address__c,
                Invoice_Email__c
            FROM Company_Information__mdt
            LIMIT 1
        ];

        ClassInvoice.EntityInvoice invoice = new ClassInvoice.EntityInvoice();
        invoice.quote = quote;
        invoice.purchaseOrder = purchaseOrder;
        invoice.dispatchOrders = dispatchOrders;
        invoice.dispatchOrderLines = dispatchOrderLines;

        invoice.companyName = company.Label;
        invoice.companyLegalName = company.Legal_Name__c;
        invoice.companyNIT = company.NIT__c;
        invoice.companyEmail = company.Invoice_Email__c;
        invoice.companyAddress = company.Address__c;
        return invoice;
    }

    @AuraEnabled
    public static String createInvoice(Invoice__c invoice, String nit, String xml){
        Purchase_Order__c purchaseOrder = [
            SELECT
                Id,
                Currency_Code__c,
                Invoice_Status__c,
                Total__c
            FROM Purchase_Order__c
            WHERE Id =: invoice.Purchase_Order__c
            LIMIT 1
        ];

        String items = '';
        List<Dispatch_Order__c> dispatchOrders = new List<Dispatch_Order__c> ();
        if (invoice.Category__c == 'Ordenes de Despacho' && String.isNotBlank(invoice.Dispatch_Orders__c)){
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
                SELECT Id, Price_USD__c, Price_GTQ__c, Name, Description__c, Unit__c
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

                price = purchaseOrder.Currency_Code__c == 'GTQ' ? product.Price_GTQ__c : product.Price_USD__c;
                invoiceDescriptionMap.get(product.Id).price = price;
                amount += quantity * price;

                invoice.Description__c += product.Name + ' | ' +  quantity + ' | ' + purchaseOrder.Currency_Code__c + price + ' \r\n';
                items += generateItem(product.Name, quantity, product.Unit__c, price);
            }
            invoice.Description__c +=  'Total: ' + purchaseOrder.Currency_Code__c + amount;
            invoice.Amount__c = amount;

        } else {
            items += generateItem(invoice.Description__c, 1, '', (Double) invoice.Amount__c);
        }

        List<String> accountInfo = getLegalAddress(nit);
        xml = xml.replace('{total}', String.valueOf(invoice.Amount__c.setScale(2)));
        xml = xml.replace('{iva}', String.valueOf((invoice.Amount__c - invoice.Amount__c / 1.12).setScale(2)));
        xml = xml.replace('{items}', items);
        xml = xml.replace('{nombreReceptor}', accountInfo[0]);
        xml = xml.replace('{direccionReceptor}', accountInfo[1]);

        //call service and response Id should be inserted in the invoice object
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

        Blob xmlBlob = Blob.valueOf(xml);
        String xmlEncoded = EncodingUtil.base64Encode(xmlBlob);

        sendInvoice(xmlEncoded);
        //return invoice.Id;
        return xml;
    }

    private static String generateItem(String name, Double quantity, String unit, Double unitPrice){
        Double totalPrice = (quantity * unitPrice * 1.0).setScale(2);
        Double iva = (totalPrice - totalPrice / 1.12).setScale(2);
        Double priceWithoutIva = (totalPrice - iva * 1.0).setScale(2);
        unitPrice = (unitPrice * 1.0).setScale(2);

        String item = '';
        item += '<dte:Item BienOServicio="B" NumeroLinea="1">\r\n';
        item += '<dte:Cantidad>' + quantity + '</dte:Cantidad>\r\n';
        item += '<dte:UnidadMedida>' + unit + '</dte:UnidadMedida>\r\n';
        item += '<dte:Descripcion>' + name + '</dte:Descripcion>\r\n';
        item += '<dte:PrecioUnitario>' + unitPrice + '</dte:PrecioUnitario>\r\n';
        item += '<dte:Precio>' + unitPrice + '</dte:Precio>\r\n';
        item += '<dte:Descuento>0.00</dte:Descuento>\r\n';
        item += '<dte:Impuestos>\r\n';
        item += '    <dte:Impuesto>\r\n';
        item += '    <dte:NombreCorto>IVA</dte:NombreCorto>\r\n';
        item += '    <dte:CodigoUnidadGravable>1</dte:CodigoUnidadGravable>\r\n';
        item += '    <dte:MontoGravable>' + iva + '</dte:MontoGravable>\r\n';
        item += '    <dte:MontoImpuesto>' + priceWithoutIva + '</dte:MontoImpuesto>\r\n';
        item += '    </dte:Impuesto>\r\n';
        item += '</dte:Impuestos>\r\n';
        item += '<dte:Total>' + totalPrice + '</dte:Total>\r\n';
        item += '</dte:Item>\r\n';

        return item;
    }

    private static String sendInvoice(String xmlEncoded){
        Company_Information__mdt company = [
            SELECT
                NIT__c,
                Invoice_Email__c
            FROM Company_Information__mdt
            LIMIT 1
        ];

        String usuario = 'MIGRACION_FEL';
        String llave = '29486704569DAD70D7D21288C3EA6BD4';
        String nit = '85346721';

        Http http = new Http();
        HttpRequest request = new HttpRequest();

        String json = '';
        json += '{';
        json += '   "nit_emisor":"' + company.NIT__c + '",';
        json += '   "correo_copia":"' + company.Invoice_Email__c + '",';
        json += '   "xml_dte":"' + xmlEncoded + '"';
        json += '}';

        request.setEndpoint('https://certificador.feel.com.gt/fel/certificacion/v2/dte/');
        request.setMethod('POST');
        request.setHeader('Usuario', usuario);
        request.setHeader('Llave', llave);
        request.setHeader('Content-Type', 'application/json');
        request.setBody(json);

        HttpResponse response = http.send(request);
        System.debug(response);

        return '';

        //https://certificador.feel.com.gt/fel/anulacion/v2/dte/
        //Do http request, using http://wsdl2apex.fuseit.com/ for generate the apex classes and test classes from the wsdl url
    }

    private static List<String> getLegalAddress(String nit){
        String usuario = 'MIGRACION_FEL';
        String clave = '29486704569DAD70D7D21288C3EA6BD4';

        String xml = '';
        xml += '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ser="http://services.ws.ingface.com/">';
        xml += '<soapenv:Header/>';
        xml += '<soapenv:Body>';
        xml += '   <ser:nitContribuyentes>';
        xml += '      <usuario>' + usuario + '</usuario>';
        xml += '      <clave>' + clave + '</clave>';
        xml += '      <nit>' + '85346721' + '</nit>';
        xml += '   </ser:nitContribuyentes>';
        xml += '</soapenv:Body>';
        xml += '</soapenv:Envelope>';

        Http http = new Http();
        HttpRequest request = new HttpRequest();

        request.setEndpoint('https://www.ingface.net:443/ServiciosIngface/ingfaceWsServices');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'text/xml; charset=character encoding');
        request.setBody(xml);

        HttpResponse response = http.send(request);
        System.debug(response);

        /*
        servicesWsIngfaceCom.ingfaceWsServicesPort service = new servicesWsIngfaceCom.ingfaceWsServicesPort();
        try {
            servicesWsIngfaceCom.cliente response = service.nitContribuyentes_Http( usuario, clave, nit);
        } catch(Exception ex){
            System.debug(ex.getMessage());
        }*/

        //convert response and send it in return
        List<String> arr = new List<String>{'Irving Cosillo','Ciudad'};
        return arr;
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
        public String companyName {get; set;}
        @AuraEnabled
        public String companyLegalName {get; set;}
        @AuraEnabled
        public String companyEmail {get; set;}
        @AuraEnabled
        public String companyNIT {get; set;}
        @AuraEnabled
        public String companyAddress {get; set;}
    }
}