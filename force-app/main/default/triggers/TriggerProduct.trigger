trigger TriggerProduct on Product__c (before insert, before update) {
    for(Product__c product : trigger.new){
        product.Stock__c = product.Stock__c > 0 ? product.Stock__c : 0;
    }
}