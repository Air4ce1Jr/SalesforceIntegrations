/**
 * @description Trigger for Invoice__c object to sync invoices to QuickBooks
 * @author Salesforce Administrator
 * @date 2024
 */
trigger InvoiceTrigger on Invoice__c (after insert, after update) {
    
    // Set to collect Invoice IDs that need QuickBooks sync
    Set<Id> invoicesToSync = new Set<Id>();
    
    // Process records after insert or update
    for (Invoice__c invoice : Trigger.new) {
        Boolean shouldSync = false;
        
        // Determine if invoice should be synced to QuickBooks
        if (Trigger.isInsert) {
            // Sync new invoices that are already approved/finalized
            if (isInvoiceReadyForSync(invoice)) {
                shouldSync = true;
            }
        } else if (Trigger.isUpdate) {
            Invoice__c oldInvoice = Trigger.oldMap.get(invoice.Id);
            
            // Sync when status changes to approved/finalized
            if (invoice.Status__c != oldInvoice.Status__c && isInvoiceReadyForSync(invoice)) {
                shouldSync = true;
            }
            
            // Sync when important invoice data changes for already approved invoices
            if (isInvoiceReadyForSync(invoice) && hasImportantFieldsChanged(invoice, oldInvoice)) {
                shouldSync = true;
            }
            
            // Sync when manually requested (if you add a sync checkbox field)
            if (invoice.Sync_to_QuickBooks__c == true && 
                (oldInvoice.Sync_to_QuickBooks__c == false || oldInvoice.Sync_to_QuickBooks__c == null)) {
                shouldSync = true;
            }
        }
        
        if (shouldSync) {
            invoicesToSync.add(invoice.Id);
        }
    }
    
    // Call the QuickBooks integration asynchronously if we have invoices to sync
    if (!invoicesToSync.isEmpty()) {
        System.debug('InvoiceTrigger: Syncing ' + invoicesToSync.size() + ' invoices to QuickBooks');
        
        // Call the async method to sync invoices
        QuickBooksInvoiceIntegration.syncInvoicesAsync(invoicesToSync);
    }
    
    /**
     * @description Check if invoice is ready to be synced to QuickBooks
     * @param invoice The invoice record to check
     * @return Boolean true if ready for sync
     */
    private static Boolean isInvoiceReadyForSync(Invoice__c invoice) {
        // Add your business logic here for when invoices should be synced
        // Common statuses: 'Approved', 'Finalized', 'Sent', 'Published'
        
        Set<String> syncStatuses = new Set<String>{
            'Approved', 
            'Finalized', 
            'Sent', 
            'Published',
            'Complete',
            'Ready'
        };
        
        return syncStatuses.contains(invoice.Status__c);
    }
    
    /**
     * @description Check if important fields have changed that require re-sync
     * @param newInvoice The new invoice record
     * @param oldInvoice The old invoice record
     * @return Boolean true if important fields changed
     */
    private static Boolean hasImportantFieldsChanged(Invoice__c newInvoice, Invoice__c oldInvoice) {
        return (
            newInvoice.Total_Amount__c != oldInvoice.Total_Amount__c ||
            newInvoice.Account__c != oldInvoice.Account__c ||
            newInvoice.Invoice_Date__c != oldInvoice.Invoice_Date__c ||
            newInvoice.Description__c != oldInvoice.Description__c
        );
    }
}