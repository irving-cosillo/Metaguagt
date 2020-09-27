@IsTest
public class TestTrigger {
    @TestSetup
    static void createProducts(){
        TestSetup.createProducts();
    }

    private static List<Product_Price__c> generatePrices(){
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
        return prices;
    }

    @IsTest
    public static void updateProductStock() {
        Product__c product = [SELECT Id, Stock__c FROM Product__c][0];
        Decimal initialStock = product.Stock__c;

        Test.startTest();
        List<Product_Price__c> prices = generatePrices();
        product = [SELECT Id, Stock__c FROM Product__c][0];
        System.assertEquals(initialStock + 16, product.Stock__c, 'Incorrect stock retrieved');
        Test.stopTest();
    }

    @IsTest
    public static void deletePrices() {
        Product__c product = [SELECT Id, Related_Price__c FROM Product__c][0];
        List<Product_Price__c> generatedPrices = generatePrices();

        List<Product_Price__c> pricesToDelete = new List<Product_Price__c>();
        pricesToDelete.add(generatedPrices[2]);

        Test.startTest();
        ClassTrigger.deletePrices(pricesToDelete);
        product = [SELECT Id, Related_Price__c FROM Product__c][0];
        System.assertNotEquals(null, product.Related_Price__c, 'No related price was set to the product after deletion');
        Test.stopTest();
    }
}
