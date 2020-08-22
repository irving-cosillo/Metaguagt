@IsTest
public class TestQuote {
    @IsTest
    static void getQuote(){
        Quote__c quote = TestSetup.createQuote();
        Test.startTest();
        Quote__c actualQuote = ClassQuote.getQuote(quote.Id);
        System.assertEquals(quote.Id, actualQuote.Id, 'Quote retrieve is not the same as expected');
        Test.stopTest();
    }

    @IsTest
    static void getQuoteLines(){
        Quote__c quote = TestSetup.createQuote();
        Test.startTest();
        List<Quote_Line__c> quoteLines = ClassQuote.getQuoteLines(quote.Id);
        System.assertEquals(3, quoteLines.size(), 'Quote lines retrieve are not the same as expected');
        Test.stopTest();
    }

    @IsTest
    static void getProductsOfLines(){
        Quote__c quote = TestSetup.createQuote();
        Test.startTest();
        List<Quote_Line__c> linesWithProducts = ClassQuote.getProductsOfLines(quote.Id);
        System.assertEquals(3, linesWithProducts.size(), 'Quote lines retrieve are not the same as expected');
        System.assertEquals('Sierras', linesWithProducts[1].Product__r.Description__c, 'Product is not the same as expected');
        Test.stopTest();
    }

    @IsTest
    static void saveQuote(){
        Quote__c quote = TestSetup.createQuote();
        List<Quote_Line__c> quoteLines = [SELECT Id FROM Quote_Line__c WHERE Quote__c =: quote.Id LIMIT 2];
        Test.startTest();
        ClassQuote.saveQuote(quote, quoteLines);
        quoteLines = [SELECT Id FROM Quote_Line__c WHERE Quote__c =: quote.Id];
        System.assertEquals(2, quoteLines.size(), 'Quote lines retrieve are not the same as expected');

        String negativeDiscountException = null;
        try {
            quote.Discount__c = -5;
            ClassQuote.saveQuote(quote, quoteLines);
        } catch (Exception e){
            negativeDiscountException = e.getMessage();
        }
        System.assertNotEquals(null, negativeDiscountException, 'Saving negative discount has to throw an exception.');

        String discountException = null;
        try {
            quote.Discount__c = 1000;
            ClassQuote.saveQuote(quote, quoteLines);
        } catch (Exception e){
            discountException = e.getMessage();
        }
        System.assertNotEquals(null, discountException, 'Saving grater discounts has to throw an exception.');

        Test.stopTest();
    }
}