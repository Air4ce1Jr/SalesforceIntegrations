/**
 * @description Trigger for Invoice__c object to sync invoices to QuickBooks
 * DEPLOY THIS AFTER installing your Revenova TMS managed package
 * 
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
                System.debug('InvoiceTrigger: New invoice ready for sync: ' + invoice.Name);
            }
        } else if (Trigger.isUpdate) {
            Invoice__c oldInvoice = Trigger.oldMap.get(invoice.Id);
            
            // Sync when status changes to approved/finalized
            if (getFieldValue(invoice, 'Status__c') != getFieldValue(oldInvoice, 'Status__c') && 
                isInvoiceReadyForSync(invoice)) {
                shouldSync = true;
                System.debug('InvoiceTrigger: Invoice status changed to sync-ready: ' + invoice.Name);
            }
            
            // Sync when important invoice data changes for already approved invoices
            if (isInvoiceReadyForSync(invoice) && hasImportantFieldsChanged(invoice, oldInvoice)) {
                shouldSync = true;
                System.debug('InvoiceTrigger: Important fields changed on approved invoice: ' + invoice.Name);
            }
            
            // Sync when manually requested (if sync checkbox field exists)
            Object syncFlag = getFieldValue(invoice, 'Sync_to_QuickBooks__c');
            Object oldSyncFlag = getFieldValue(oldInvoice, 'Sync_to_QuickBooks__c');
            if (syncFlag == true && (oldSyncFlag == false || oldSyncFlag == null)) {
                shouldSync = true;
                System.debug('InvoiceTrigger: Manual sync requested for invoice: ' + invoice.Name);
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
        try {
            QuickBooksInvoiceIntegration.syncInvoicesAsync(invoicesToSync);
        } catch (Exception e) {
            System.debug('InvoiceTrigger: Error calling sync method: ' + e.getMessage());
            // Log the error but don't fail the trigger
        }
    }
    
    /**
     * @description Check if invoice is ready to be synced to QuickBooks
     * @param invoice The invoice record to check
     * @return Boolean true if ready for sync
     */
    private static Boolean isInvoiceReadyForSync(Invoice__c invoice) {
        // Get the status field value (handles different possible field names)
        Object statusValue = getFieldValue(invoice, 'Status__c');
        
        if (statusValue == null) {
            return false;
        }
        
        String status = String.valueOf(statusValue);
        
        // Define statuses that indicate the invoice is ready for QuickBooks sync
        Set<String> syncStatuses = new Set<String>{
            'Approved', 
            'Finalized', 
            'Sent', 
            'Published',
            'Complete',
            'Ready',
            'Active',
            'Confirmed',
            'Final',
            'Closed'
        };
        
        return syncStatuses.contains(status);
    }
    
    /**
     * @description Check if important fields have changed that require re-sync
     * @param newInvoice The new invoice record
     * @param oldInvoice The old invoice record
     * @return Boolean true if important fields changed
     */
    private static Boolean hasImportantFieldsChanged(Invoice__c newInvoice, Invoice__c oldInvoice) {
        // Check common field names that might exist in Revenova TMS
        return (
            getFieldValue(newInvoice, 'Total_Amount__c') != getFieldValue(oldInvoice, 'Total_Amount__c') ||
            getFieldValue(newInvoice, 'Amount__c') != getFieldValue(oldInvoice, 'Amount__c') ||
            getFieldValue(newInvoice, 'Total__c') != getFieldValue(oldInvoice, 'Total__c') ||
            getFieldValue(newInvoice, 'Account__c') != getFieldValue(oldInvoice, 'Account__c') ||
            getFieldValue(newInvoice, 'Customer__c') != getFieldValue(oldInvoice, 'Customer__c') ||
            getFieldValue(newInvoice, 'Invoice_Date__c') != getFieldValue(oldInvoice, 'Invoice_Date__c') ||
            getFieldValue(newInvoice, 'Date__c') != getFieldValue(oldInvoice, 'Date__c') ||
            getFieldValue(newInvoice, 'Description__c') != getFieldValue(oldInvoice, 'Description__c') ||
            getFieldValue(newInvoice, 'Notes__c') != getFieldValue(oldInvoice, 'Notes__c')
        );
    }
    
    /**
     * @description Safely get field value from SObject (handles missing fields)
     * @param record The SObject record
     * @param fieldName The field API name
     * @return Object The field value or null if field doesn't exist
     */
    private static Object getFieldValue(SObject record, String fieldName) {
        try {
            return record.get(fieldName);
        } catch (Exception e) {
            // Field doesn't exist, return null
            return null;
        }
    }
}