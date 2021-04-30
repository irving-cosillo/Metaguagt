//Do http request, using http://wsdl2apex.fuseit.com/ for generate the apex classes and test classes from the wsdl url
    
public with sharing class ClassInvoice {

    public class EntityInvoiceWrapper {
        @AuraEnabled
        public String xml;
        @AuraEnabled
        public String xmlEncoded;
        @AuraEnabled
        public Invoice__c invoice;
        @AuraEnabled
        public Purchase_Order__c purchaseOrder;
        @AuraEnabled
        public List<Dispatch_Order__c> dispatchOrders;
    }

    public class EntityInvoiceLine{
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
        public Company_Information__mdt companyInfo {get; set;}
    }

    public class EntityLegalInformation {
        @AuraEnabled
        public String legalName;
        @AuraEnabled
        public String legalAddress;
    }

    public class EntitySignInvoiceResponse {
        @AuraEnabled
        public Boolean resultado;
        @AuraEnabled
        public String descripcion;
        @AuraEnabled
        public string archivo;
    }

    public class EntityCanelInvoiceInformation {
        @AuraEnabled
        public Invoice__c invoice {get; set;}
        @AuraEnabled
        public Company_Information__mdt companyInfo {get; set;}
    }


    @AuraEnabled
    public static EntityInvoice getPurchaseOrderInfo(String purchaseOrderId){
        List<Purchase_Order__c> purchaseOrderList = [
            SELECT 
                Order_Id__c, 
                Account__c,
                Account__r.NIT__c,
                Account__r.Phone,
                Quote__c, 
                Quote__r.Sales_User__c,
                Quote__r.Payment__c,
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
        Quote__c quote = [
            SELECT 
                Credit__c, 
                Payment__c 
            FROM Quote__c 
            WHERE Id =: purchaseOrder.Quote__c 
            LIMIT 1
        ];
        Map<Id, Dispatch_Order__c> dispatchOrdersMap = new Map<Id, Dispatch_Order__c>([
            SELECT 
                Id, 
                Name
            FROM Dispatch_Order__c 
            WHERE 
                Purchase_Order__c =: purchaseOrderId AND 
                Invoice__c = null 
        ]);

        Set<Id> dispatchOrdersId = dispatchOrdersMap.keySet();
        List<Dispatch_Order__c> dispatchOrders = dispatchOrdersMap.values();
        List<Dispatch_Order_Line__c> dispatchOrderLines = [
            SELECT
                Dispatch_Order__c,
                Product_Name__c, 
                Quantity__c,
                Purchase_Order_Line__r.Quote_Line__r.Product__r.Price_USD__c,
                Purchase_Order_Line__r.Quote_Line__r.Product__r.Price_GTQ__c
            FROM Dispatch_Order_Line__c 
            WHERE Dispatch_Order__c IN  :dispatchOrdersId
        ];

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

        EntityInvoice invoice = new EntityInvoice();
        invoice.quote = quote;
        invoice.purchaseOrder = purchaseOrder;
        invoice.dispatchOrders = dispatchOrders;
        invoice.dispatchOrderLines = dispatchOrderLines;
        invoice.companyInfo = companyInfo;

        return invoice;
    }

    @AuraEnabled
    public static EntityLegalInformation getClientLegalInformation(String nit, Company_Information__mdt companyInfo){
        String xml = '';
        xml += '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ser="http://services.ws.ingface.com/">';
        xml += '<soapenv:Header/>';
        xml += '<soapenv:Body>';
        xml += '   <ser:nitContribuyentes>';
        xml += '      <usuario>CONSUMO_NIT</usuario>';
        xml += '      <clave>58B45D8740C791420C53A49FFC924A1B58B45D8740C791420C53A49FFC924A1B</clave>';
        xml += '      <nit>' + nit + '</nit>';
        xml += '   </ser:nitContribuyentes>';
        xml += '</soapenv:Body>';
        xml += '</soapenv:Envelope>';

        Http http = new Http();
        HttpRequest request = new HttpRequest();

        request.setEndpoint(companyInfo.Infile_NIT_Endpoint__c);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'text/xml; charset=character encoding');
        request.setBody(xml);

        HttpResponse response;
        String bodyResponse;

        if(Test.isRunningTest()){
            bodyResponse = '<direccion_completa>Test Legal Address</direccion_completa>';
            bodyResponse += '<nombre>Cosillo, Aragon, , Irving, Eduardo</nombre>';
        } else {
            response = http.send(request);
            bodyResponse = response.getBody();
        }
        
        Integer addressStartIndex = bodyResponse.indexOf('<direccion_completa>') + 20;
        Integer addressEndIndex = bodyResponse.indexOf('</direccion_completa>');
        String legalAddress = bodyResponse.substring(addressStartIndex, addressEndIndex);

        Integer nameStartIndex = bodyResponse.indexOf('<nombre>') + 8;
        Integer nameEndIndex = bodyResponse.indexOf('</nombre>');
        List<String> legalNameArr = bodyResponse.substring(nameStartIndex, nameEndIndex).split(',');
        String legalName = String.format('{3} {4} {0} {1}', legalNameArr);

        EntityLegalInformation legalInfo = new EntityLegalInformation();
        legalInfo.legalName = legalName;
        legalInfo.legalAddress = legalAddress;

        return legalInfo;
    }

    @AuraEnabled
    public static EntityInvoiceWrapper getInvoiceWrapper(Invoice__c invoice, String xml){
        
        Purchase_Order__c purchaseOrder = [
            SELECT 
                Id,
                Currency_Code__c, 
                Invoice_Status__c, 
                Billed_Amount__c, 
                Total__c 
            FROM Purchase_Order__c 
            WHERE 
                Id =: invoice.Purchase_Order__c 
            LIMIT 1
        ];

        String items = '';
        List<Dispatch_Order__c> dispatchOrders = new List<Dispatch_Order__c> ();
        if (invoice.Category__c == 'Ordenes de Despacho' && String.isNotBlank(invoice.Dispatch_Orders__c)){
            List<String> dispatchOrdersId = invoice.Dispatch_Orders__c.remove('"').remove('[').remove(']').split(',');
            dispatchOrders = [ SELECT Id, State__c, Purchase_Order__c FROM Dispatch_Order__c WHERE Id IN : dispatchOrdersId];

            List<Dispatch_Order_Line__c> dispatchOrderLines = [SELECT Id, Quantity__c, Purchase_Order_Line__c, Purchase_Order_Line__r.Quote_Line__r.Product__c FROM Dispatch_Order_Line__c WHERE Dispatch_Order__c IN : dispatchOrders];

            Map<String,EntityInvoiceLine> invoiceDescriptionMap = new Map<String,EntityInvoiceLine>();
            EntityInvoiceLine line;
            String productId ;

            //Repeated lines sum their quantities
            for (Dispatch_Order_Line__c dispatchOrderLine : dispatchOrderLines){
                productId = dispatchOrderLine.Purchase_Order_Line__r.Quote_Line__r.Product__c;
                if (invoiceDescriptionMap.get(productId) == null) {
                    line = new EntityInvoiceLine();
                    line.productId = productId;
                    line.quantity = dispatchOrderLine.Quantity__c;
                    invoiceDescriptionMap.put(productId, line);
                } else {
                    invoiceDescriptionMap.get(productId).quantity += dispatchOrderLine.Quantity__c;
                }
            }

            Set<String> productsId = invoiceDescriptionMap.keySet();
            List<Product__c> products = [
                SELECT 
                    Id, 
                    Price_USD__c, 
                    Price_GTQ__c, 
                    Name, 
                    Description__c, 
                    Unit__c 
                FROM Product__c 
                WHERE Id IN : productsId
            ];

            Double price = 0;
            Double amount = 0;
            Double quantity = 0;
            Integer itemsCount = 0;
            invoice.Description__c = '';
            for (Product__c product: products) {
                invoiceDescriptionMap.get(product.Id).code = product.Name;
                invoiceDescriptionMap.get(product.Id).description = product.Description__c;
                quantity = invoiceDescriptionMap.get(product.Id).quantity;

                price = purchaseOrder.Currency_Code__c == 'GTQ' ? product.Price_GTQ__c : product.Price_USD__c;
                invoiceDescriptionMap.get(product.Id).price = price;
                amount += quantity * price;

                invoice.Description__c += product.Name + ' | ' +  quantity + ' | ' + purchaseOrder.Currency_Code__c + price + ' \r\n';
                itemsCount += 1;
                items += generateItem(product.Description__c, quantity, product.Unit__c, price, itemsCount);
            }
            invoice.Description__c +=  'Total: ' + purchaseOrder.Currency_Code__c + amount;
            invoice.Amount__c = amount;
        } else {
            items += generateItem(invoice.Description__c, 1, '', (Double) invoice.Amount__c, 1);
        }

        xml = xml.replace('{total}', String.valueOf(invoice.Amount__c.setScale(2)));
        xml = xml.replace('{iva}', String.valueOf((invoice.Amount__c - invoice.Amount__c / 1.12).setScale(2)));
        xml = xml.replace('{items}', items);

        Blob xmlBlob = Blob.valueOf(xml);
        String xmlEncoded = EncodingUtil.base64Encode(xmlBlob);

        EntityInvoiceWrapper wrapper = new EntityInvoiceWrapper();
        wrapper.xml = xml;
        wrapper.xmlEncoded = xmlEncoded;
        wrapper.invoice = invoice;
        wrapper.purchaseOrder = purchaseOrder;
        wrapper.dispatchOrders = dispatchOrders;

        return wrapper;
    }

    private static String generateItem(String name, Double quantity, String unit, Double unitPrice, Integer line){
        Double totalPrice = (quantity * unitPrice * 1.0).setScale(2);
        Double iva = (totalPrice - totalPrice / 1.12).setScale(2);
        Double priceWithoutIva = (totalPrice - iva * 1.0).setScale(2);
        unitPrice = (unitPrice * 1.0).setScale(2);

        String margin = '                    ';
        String item = '';
        item += '<dte:Item BienOServicio="B" NumeroLinea="' + line + '">\r\n';
        item += margin + '    <dte:Cantidad>' + quantity + '</dte:Cantidad>\r\n';
        item += margin + '    <dte:UnidadMedida>UND</dte:UnidadMedida>\r\n';
        item += margin + '    <dte:Descripcion>' + name + '</dte:Descripcion>\r\n';
        item += margin + '    <dte:PrecioUnitario>' + unitPrice + '</dte:PrecioUnitario>\r\n';
        item += margin + '    <dte:Precio>' + totalPrice + '</dte:Precio>\r\n';
        item += margin + '    <dte:Descuento>0.00</dte:Descuento>\r\n';
        item += margin + '    <dte:Impuestos>\r\n';
        item += margin + '        <dte:Impuesto>\r\n';
        item += margin + '            <dte:NombreCorto>IVA</dte:NombreCorto>\r\n';
        item += margin + '            <dte:CodigoUnidadGravable>1</dte:CodigoUnidadGravable>\r\n';
        item += margin + '            <dte:MontoGravable>' + priceWithoutIva + '</dte:MontoGravable>\r\n';
        item += margin + '            <dte:MontoImpuesto>' + iva + '</dte:MontoImpuesto>\r\n';
        item += margin + '            </dte:Impuesto>\r\n';
        item += margin + '    </dte:Impuestos>\r\n';
        item += margin + '    <dte:Total>' + totalPrice + '</dte:Total>\r\n';
        item += margin + '</dte:Item>\r\n';

        return item;
    }

    @AuraEnabled
    public static EntitySignInvoiceResponse signInvoice(String xmlEncoded, Company_Information__mdt companyInfo, Boolean isAnulation ){
        Http http = new Http();
        HttpRequest request = new HttpRequest();

        String isAnulationStr = isAnulation ? 'S' : 'N';
        String json = '';
        json += '{';
        json += '   "llave":"' + companyInfo.Infile_Sign_Key__c + '",';
        json += '   "archivo":"' + xmlEncoded + '",';
        json += '   "codigo":"0",';
        json += '   "alias":"' + companyInfo.Infile_User__c + '",';
        json += '   "es_anulacion":"' + isAnulationStr + '"';
        json += '}';

        request.setEndpoint(companyInfo.Infile_Sign_Endpoint__c);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody(json);

        if(Test.isRunningTest()){
            EntitySignInvoiceResponse response = new EntitySignInvoiceResponse();
            response.resultado = true;
            return response;
        } else {
            HttpResponse response = http.send(request);
            String bodyResponse = response.getBody();
            ClassInvoice.EntitySignInvoiceResponse invoiceResponse = (ClassInvoice.EntitySignInvoiceResponse) System.JSON.deserialize(bodyResponse, ClassInvoice.EntitySignInvoiceResponse.class);
            return invoiceResponse;
        }
    }

    @AuraEnabled
    public static EntityInvoiceResponse processInvoice(String xmlSignedEncoded, Company_Information__mdt companyInfo, String email, String certificateId, Boolean isAnulation){
        Http http = new Http();
        HttpRequest request = new HttpRequest();

        String endpoint = isAnulation ? companyInfo.Infile_Anulation_Endpoint__c : companyInfo.Infile_Certification_Endpoint__c;
        String json = '';
        json += '{';
        json += '   "nit_emisor":"' + companyInfo.Infile_NIT__c.replace('-', '') + '",';
        json += '   "correo_copia":"' + email + '",';
        json += '   "xml_dte":"' + xmlSignedEncoded + '"';
        json += '}';

        request.setEndpoint(endpoint);
        request.setMethod('POST');
        request.setHeader('Usuario', companyInfo.Infile_User__c);
        request.setHeader('Llave', companyInfo.Infile_Certification_Key__c);
        request.setHeader('Identificador', certificateId);
        request.setHeader('Content-Type', 'application/json');
        request.setBody(json);

        if(Test.isRunningTest()){
            EntityInvoiceResponse response = new EntityInvoiceResponse();
            response.resultado = true;
            return response;
        } else {
            HttpResponse response = http.send(request);
            String bodyResponse = response.getBody();

            Integer cont = 0;
            Integer step = 250;
            while (cont+step < bodyResponse.length()){
                System.debug(bodyResponse.substring(cont, cont+step));
                cont += step;
            }
            System.debug(bodyResponse.substring(cont, bodyResponse.length()));
            EntityInvoiceResponse invoiceResponse = (EntityInvoiceResponse) System.JSON.deserialize(bodyResponse, EntityInvoiceResponse.class);
            return invoiceResponse;
        }
    }

    @AuraEnabled
    public static String insertInvoiceApex(Invoice__c invoice, Purchase_Order__c purchaseOrder, List<Dispatch_Order__c> dispatchOrders){
        insert invoice;
        
        if (dispatchOrders.size() > 0) {
            for(Dispatch_Order__c dispatchOrder : dispatchOrders){
                dispatchOrder.Invoice__c = invoice.Id;
            }

            update dispatchOrders;
        }

        try {
            updatePurchaseOrderStateAndAmount(invoice);
        } catch (Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }

        return invoice.Id;
    }

    @AuraEnabled
    public static void cancelInvoiceApex(String invoiceId, String cancellationReason){
        Invoice__c invoice = [
            SELECT 
                Id, 
                Canceled__c, 
                Cancellation_Reason__c, 
                Purchase_Order__c 
            FROM Invoice__c 
            WHERE Id =: invoiceId
        ];

        List<Dispatch_Order__c> dispatchOrders = [
            SELECT 
                Invoice__c 
            FROM Dispatch_Order__c 
            WHERE Invoice__c =: invoiceId
        ];

        for(Dispatch_Order__c dispatchOrder : dispatchOrders){
            dispatchOrder.Invoice__c = null;
        }

        update dispatchOrders;

        invoice.Canceled__c = true;
        invoice.Cancellation_Reason__c = cancellationReason;
        update invoice;

        try {
            updatePurchaseOrderStateAndAmount(invoice);    
        } catch (Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }

    private static void updatePurchaseOrderStateAndAmount(Invoice__c invoice){

        Purchase_Order__c purchaseOrder = [
            SELECT
                Id,
                Currency_Code__c,
                Billed_Amount__c, 
                Total__c 
            FROM Purchase_Order__c 
            WHERE Id =: invoice.Purchase_Order__c
        ];

        List<Invoice__c> relatedInvoices = [
            SELECT 
                Amount__c, 
                Canceled__c 
            FROM Invoice__c 
            WHERE Purchase_Order__c =: purchaseOrder.Id
        ];

        Double billedAmount = 0;
        for (Invoice__c relatedInvoice : relatedInvoices){
            if (!relatedInvoice.Canceled__c){
                billedAmount += relatedInvoice.Amount__c;
            }
        }

        purchaseOrder.Billed_Amount__c = billedAmount;

        if (billedAmount <= 0){
            purchaseOrder.Invoice_Status__c = 'Pendiente';
        } else if (billedAmount < purchaseOrder.Total__c){
            purchaseOrder.Invoice_Status__c = 'Parcialmente';
        } else if (billedAmount == purchaseOrder.Total__c){
            purchaseOrder.Invoice_Status__c = 'Completado';
        } else {
            throw new AuraHandledException('El monto excede el total de la orden de compra.');
        }

        update purchaseOrder;
    }

    @AuraEnabled
    public static EntityCanelInvoiceInformation getInvoiceInformation(String invoiceId){
        Invoice__c invoice = [
            SELECT 
                Id, 
                Name, 
                Date__c, 
                External_UUID__c, 
                Purchase_Order__r.Account__r.Id 
            FROM Invoice__c 
            WHERE Id =: invoiceId 
            LIMIT 1
        ];
        Company_Information__mdt companyInfo = [
            SELECT 
                Invoice_Email__c, 
                Infile_User__c, 
                Infile_NIT__c, 
                Infile_Sign_Key__c, 
                Infile_Certification_Key__c, 
                Infile_Anulation_Endpoint__c, 
                Infile_Sign_Endpoint__c 
            FROM Company_Information__mdt 
            LIMIT 1
        ];

        EntityCanelInvoiceInformation response = new EntityCanelInvoiceInformation();
        response.invoice = invoice;
        response.companyInfo = companyInfo;
        return response;
    }
}