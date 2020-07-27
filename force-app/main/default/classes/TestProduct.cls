@IsTest
public class TestProduct {
    @TestSetup
    static void createProducts(){
        TestSetup.createProducts();
    }

    @IsTest
    public static void getProducts() {
        Test.startTest();
        List<Product__c> allProducts = ClassProduct.getProducts('p');
        List<Product__c> oneProduct = ClassProduct.getProducts('Sello');
        List<Product__c> noProducts = ClassProduct.getProducts('No match string');
        System.assertEquals(3, allProducts.size(), 'Not all products where retrieved');
        System.assertEquals(1, oneProduct.size(), 'Specific product was not found');
        System.assertEquals(0, noProducts.size(), 'Found products when it was not supposed to find');
        Test.stopTest();
    }
}
