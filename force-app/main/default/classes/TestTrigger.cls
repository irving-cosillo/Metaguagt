@IsTest
public class TestTrigger {
    @TestSetup
    static void createProducts(){
        TestSetup.createProducts();
    }

    @IsTest
    public static void updateProductStock() {
        Product__c product = [SELECT Id, Stock__c FROM Product__c][0];
        List<Product_Price__c> prices = new List<Product_Price__c>();
        Product_Price__c price;

        price = new Product_Price__c();
        price.Quantity__c = 1;
        price.Unit_Cost_GTQ__c = 10;
        price.Profit__c = 100;
        price.Unit_Price_GTQ__c = 20;
        price.Product__c = product.Id;
        prices.add(price);

        price = new Product_Price__c();
        price.Quantity__c = 10;
        price.Unit_Cost_GTQ__c = 10;
        price.Profit__c = 100;
        price.Unit_Price_GTQ__c = 20;
        price.Product__c = product.Id;
        prices.add(price);

        price = new Product_Price__c();
        price.Quantity__c = 5;
        price.Unit_Cost_GTQ__c = 10;
        price.Profit__c = 100;
        price.Unit_Price_GTQ__c = 20;
        price.Product__c = product.Id;
        prices.add(price);

        insert prices;

        Test.startTest();
        ClassTrigger.updateProductStock(prices, true);
        product = [SELECT Id, Stock__c FROM Product__c][0];

        System.assertEquals(16, product.Stock__c, 'Incorrect stock retrieved');
        Test.stopTest();
    }
}
