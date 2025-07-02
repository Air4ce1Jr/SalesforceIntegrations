/**
 * @description Test script to create a customer account for QuickBooks integration testing
 * Run this in Developer Console's Execute Anonymous window
 * 
 * This will:
 * 1. Create a test customer account with Type = 'Customer'
 * 2. Trigger the AccountTrigger to sync the customer to QuickBooks
 * 3. Display debug information about the sync process
 */

try {
    // Create a test customer account
    Account testCustomer = new Account(
        Name = 'Test QuickBooks Customer Corp',
        Type = 'Customer',
        Phone = '(555) 987-6543',
        BillingStreet = '456 Commerce Street',
        BillingCity = 'Chicago',
        BillingState = 'Illinois',
        BillingPostalCode = '60601',
        BillingCountry = 'United States',
        Website = 'https://testcustomer.com',
        Description = 'Test customer account for QuickBooks integration - Created ' + System.now()
    );
    
    System.debug('🚀 Creating test customer account...');
    
    // Insert the account - this will trigger the AccountTrigger
    insert testCustomer;
    
    System.debug('✅ Test customer created successfully!');
    System.debug('📋 Account Details:');
    System.debug('   - Account ID: ' + testCustomer.Id);
    System.debug('   - Account Name: ' + testCustomer.Name);
    System.debug('   - Account Type: ' + testCustomer.Type);
    System.debug('   - Phone: ' + testCustomer.Phone);
    
    // Query the account to see if QuickBooks fields were populated
    Account updatedAccount = [
        SELECT Id, Name, Type, QuickBooks_Customer_Id__c, QuickBooks_Customer_SyncToken__c, QuickBooks_Email__c
        FROM Account 
        WHERE Id = :testCustomer.Id
        LIMIT 1
    ];
    
    System.debug('🔄 QuickBooks Sync Status:');
    if (String.isNotBlank(updatedAccount.QuickBooks_Customer_Id__c)) {
        System.debug('   ✅ SUCCESS: Customer synced to QuickBooks!');
        System.debug('   - QuickBooks Customer ID: ' + updatedAccount.QuickBooks_Customer_Id__c);
        System.debug('   - Sync Token: ' + updatedAccount.QuickBooks_Customer_SyncToken__c);
    } else {
        System.debug('   ⏳ PENDING: Customer sync may be processing asynchronously');
        System.debug('   - Check debug logs for QuickBooksInvoiceIntegration activity');
        System.debug('   - Verify named credential "QuickBooks_NC" is properly configured');
    }
    
    System.debug('📝 Next Steps:');
    System.debug('   1. Check the debug logs above for any sync errors');
    System.debug('   2. Verify the customer appears in your QuickBooks org');
    System.debug('   3. If sync failed, check the named credential configuration');
    
} catch (Exception e) {
    System.debug('❌ ERROR creating test customer: ' + e.getMessage());
    System.debug('📋 Stack Trace: ' + e.getStackTraceString());
}