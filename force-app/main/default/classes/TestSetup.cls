@IsTest
public class TestSetup {
    public static List<Product__c> createProducts(){
        List<Product__c> products = new List<Product__c>();
        Product__c product;

        product = new Product__c();
        product.Description__c = 'Sello Espirometálico 1" 900-1500 PSI';
        product.Brand__c = 'Flexitallic';
        product.Family__c = 'Sellos Hidráulicos';
        product.Subfamily__c = 'Espirometálico tipo CG';
        product.Unit__c = 'Unidad';
        product.Stock__c = 50;
        product.Stock_Minimum__c = 0;
        product.Stock_Maximum__c = 100;
        products.add(product);

        product = new Product__c();
        product.Description__c = 'Sierras';
        product.Brand__c = 'Genérico';
        product.Family__c = 'Herramienta de Corte';
        product.Subfamily__c = 'Cortador Vertical';
        product.Unit__c = 'Unidad';
        product.Stock__c = 50;
        product.Stock_Minimum__c = 0;
        product.Stock_Maximum__c = 100;
        products.add(product);

        product = new Product__c();
        product.Description__c = 'Buril de Cobalto';
        product.Brand__c = 'Micro 100';
        product.Family__c = 'Herramienta de Corte';
        product.Subfamily__c = 'Buril de Cobalto';
        product.Unit__c = 'Unidad';
        product.Stock__c = 50;
        product.Stock_Minimum__c = 0;
        product.Stock_Maximum__c = 100;
        products.add(product);

        insert products;

        List<Product_Price__c> prices = new List<Product_Price__c>();
        Product_Price__c price = new Product_Price__c();
        price.Quantity__c = 5;
        price.Profit__c = 50;
        price.Unit_Cost_GTQ__c = 100;
        price.Unit_Price_GTQ__c = 150;
        price.Product__c = products[0].Id;
        prices.add(price);

        price = new Product_Price__c();
        price.Quantity__c = 6;
        price.Profit__c = 50;
        price.Unit_Cost_GTQ__c = 200;
        price.Unit_Price_GTQ__c = 300;
        price.Product__c = products[1].Id;
        prices.add(price);

        price = new Product_Price__c();
        price.Quantity__c = 7;
        price.Profit__c = 50;
        price.Unit_Cost_GTQ__c = 400;
        price.Unit_Price_GTQ__c = 600;
        price.Product__c = products[2].Id;
        prices.add(price);

        insert prices;

        products[0].Related_Price__c = prices[0].Id;
        products[1].Related_Price__c = prices[1].Id;
        products[2].Related_Price__c = prices[2].Id;

        update products;

        return products;
    }

    public static Quote__c createQuote(){
        String i = getUUID();
        Account account = new Account(Name = 'Ingenio Magdalena - ' + i);
        insert account;

        Contact contact = new Contact();
        contact.AccountId = account.Id;
        contact.FirstName = 'Hugo';
        contact.LastName = 'López - ' + i;
        insert contact;

        Quote__c quote = new Quote__c();
        quote.Account__c = account.Id;
        quote.Contact__c = contact.Id;
        quote.Currency_Code__c = 'GTQ';
        quote.Payment__c = 'Al contado';
        quote.Offer_Time__c = 15;
        quote.Sales_User__c = 'Sala de Ventas';
        insert quote;

        List<Product__c> products = TestSetup.createProducts();
        List<Quote_Line__c> quoteLines =  new List<Quote_Line__c>();
        Quote_Line__c quoteLine;

        quoteLine = new Quote_Line__c();
        quoteLine.Quantity__c = 10;
        quoteLine.Quote__c = quote.Id;
        quoteLine.Index__c = 0;
        quoteLine.Product__c = products[0].Id;
        quoteLine.Product_Price__c = products[0].Related_Price__c;
        quoteLine.Time__c = 10;
        quoteLine.Type__c = 'Normal';
        quoteLine.Subtotal_GTQ__C = 10*150;
        quoteLine.Subtotal_USD__C = 15;
        quoteLines.add(quoteLine);

        quoteLine = new Quote_Line__c();
        quoteLine.Quantity__c = 11;
        quoteLine.Quote__c = quote.Id;
        quoteLine.Index__c = 1;
        quoteLine.Product__c = products[1].Id;
        quoteLine.Product_Price__c = products[1].Related_Price__c;
        quoteLine.Time__c = 11;
        quoteLine.Type__c = 'Normal';
        quoteLine.Subtotal_GTQ__C = 11*300;
        quoteLine.Subtotal_USD__C = 15;
        quoteLines.add(quoteLine);

        quoteLine = new Quote_Line__c();
        quoteLine.Quantity__c = 12;
        quoteLine.Quote__c = quote.Id;
        quoteLine.Index__c = 2;
        quoteLine.Product__c = products[2].Id;
        quoteLine.Product_Price__c = products[2].Related_Price__c;
        quoteLine.Time__c = 12;
        quoteLine.Type__c = 'Normal';
        quoteLine.Subtotal_GTQ__C = 12*600;
        quoteLine.Subtotal_USD__C = 15;
        quoteLines.add(quoteLine);

        insert quoteLines;
        return quote;
    }

    public static String getUUID()
    {
        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        String guid = h.SubString(0,8)+ '-' + h.SubString(8,12) + '-' + h.SubString(12,16) + '-' + h.SubString(16,20) + '-' + h.substring(20);
        system.debug(guid);
        return guid;
    }
}