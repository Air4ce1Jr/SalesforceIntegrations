/**
 * @description QuickBooks data models and wrapper classes
 * @author Salesforce Administrator
 * @date 2024
 */
public class QuickBooksModels {
    
    /**
     * @description Wrapper class for QuickBooks invoice response
     */
    public class QBInvoiceResponse {
        public QBInvoice Invoice;
        public String responseTime;
        public String QueryResponse;
    }
    
    /**
     * @description Wrapper class for QuickBooks customer response
     */
    public class QBCustomerResponse {
        public List<QBCustomer> Customer;
        public String QueryResponse;
    }
    
    /**
     * @description Wrapper class for QuickBooks invoice
     */
    public class QBInvoice {
        public String Id;
        public String SyncToken;
        public String TxnDate;
        public Decimal TotalAmt;
        public QBCustomerRef CustomerRef;
        public List<QBLineItem> Line;
        public String DocNumber;
        public String DueDate;
        public String PrivateNote;
        public String CustomerMemo;
    }
    
    /**
     * @description Wrapper class for customer reference in QuickBooks
     */
    public class QBCustomerRef {
        public String value;
        public String name;
    }
    
    /**
     * @description Wrapper class for QuickBooks customer
     */
    public class QBCustomer {
        public String Id;
        public String SyncToken;
        public String Name;
        public String CompanyName;
        public String GivenName;
        public String FamilyName;
        public String DisplayName;
        public String PrimaryPhone;
        public String PrimaryEmailAddr;
        public QBAddress BillAddr;
        public QBAddress ShipAddr;
        public String Notes;
        public Boolean Active;
    }
    
    /**
     * @description Wrapper class for QuickBooks address
     */
    public class QBAddress {
        public String Line1;
        public String Line2;
        public String City;
        public String Country;
        public String CountrySubDivisionCode;
        public String PostalCode;
    }
    
    /**
     * @description Wrapper class for QuickBooks line items
     */
    public class QBLineItem {
        public String Id;
        public Decimal Amount;
        public String Description;
        public String DetailType;
        public QBSalesItemLineDetail SalesItemLineDetail;
    }
    
    /**
     * @description Wrapper class for sales item line detail
     */
    public class QBSalesItemLineDetail {
        public QBItemRef ItemRef;
        public Decimal Qty;
        public Decimal UnitPrice;
    }
    
    /**
     * @description Wrapper class for item reference
     */
    public class QBItemRef {
        public String value;
        public String name;
    }
    
    /**
     * @description Convert Salesforce Account to QuickBooks Customer
     * @param account The Salesforce Account to convert
     * @return QuickBooks Customer object
     */
    public static QBCustomer convertAccountToCustomer(Account account) {
        QBCustomer customer = new QBCustomer();
        
        customer.Name = account.Name;
        customer.CompanyName = account.Name;
        customer.DisplayName = account.Name;
        customer.PrimaryPhone = account.Phone;
        customer.Active = true;
        
        // Set billing address if available
        if (String.isNotBlank(account.BillingStreet) || 
            String.isNotBlank(account.BillingCity) || 
            String.isNotBlank(account.BillingState)) {
            
            customer.BillAddr = new QBAddress();
            customer.BillAddr.Line1 = account.BillingStreet;
            customer.BillAddr.City = account.BillingCity;
            customer.BillAddr.CountrySubDivisionCode = account.BillingState;
            customer.BillAddr.PostalCode = account.BillingPostalCode;
            customer.BillAddr.Country = account.BillingCountry;
        }
        
        return customer;
    }
    
    /**
     * @description Convert Salesforce Invoice to QuickBooks Invoice
     * @param invoice The Salesforce Invoice to convert
     * @param account The related Account
     * @param qbCustomerId The QuickBooks Customer ID
     * @return QuickBooks Invoice object
     */
    public static QBInvoice convertSalesforceInvoice(SObject invoice, Account account, String qbCustomerId) {
        QBInvoice qbInvoice = new QBInvoice();
        
        // Set basic invoice fields
        qbInvoice.TxnDate = String.valueOf(Date.today());
        qbInvoice.DueDate = String.valueOf(Date.today().addDays(30));
        
        // Set customer reference
        qbInvoice.CustomerRef = new QBCustomerRef();
        qbInvoice.CustomerRef.value = qbCustomerId;
        qbInvoice.CustomerRef.name = account.Name;
        
        // Try to get invoice fields if they exist
        try {
            if (invoice.get('Name') != null) {
                qbInvoice.DocNumber = String.valueOf(invoice.get('Name'));
            }
            
            if (invoice.get('Total_Amount__c') != null) {
                qbInvoice.TotalAmt = (Decimal) invoice.get('Total_Amount__c');
            }
            
            if (invoice.get('Invoice_Date__c') != null) {
                Date invoiceDate = (Date) invoice.get('Invoice_Date__c');
                qbInvoice.TxnDate = String.valueOf(invoiceDate);
            }
            
            if (invoice.get('Due_Date__c') != null) {
                Date dueDate = (Date) invoice.get('Due_Date__c');
                qbInvoice.DueDate = String.valueOf(dueDate);
            }
            
            if (invoice.get('Description__c') != null) {
                qbInvoice.PrivateNote = String.valueOf(invoice.get('Description__c'));
            }
        } catch (Exception e) {
            System.debug('Some invoice fields not available: ' + e.getMessage());
        }
        
        // Create a default line item if total amount is available
        if (qbInvoice.TotalAmt != null && qbInvoice.TotalAmt > 0) {
            QBLineItem lineItem = new QBLineItem();
            lineItem.Amount = qbInvoice.TotalAmt;
            lineItem.Description = 'Service - ' + (qbInvoice.DocNumber != null ? qbInvoice.DocNumber : 'Invoice');
            lineItem.DetailType = 'SalesItemLineDetail';
            
            lineItem.SalesItemLineDetail = new QBSalesItemLineDetail();
            lineItem.SalesItemLineDetail.Qty = 1;
            lineItem.SalesItemLineDetail.UnitPrice = qbInvoice.TotalAmt;
            
            // Use default service item (QuickBooks usually has a default service item)
            lineItem.SalesItemLineDetail.ItemRef = new QBItemRef();
            lineItem.SalesItemLineDetail.ItemRef.value = '1'; // Default service item ID
            lineItem.SalesItemLineDetail.ItemRef.name = 'Services';
            
            qbInvoice.Line = new List<QBLineItem>{lineItem};
        }
        
        return qbInvoice;
    }
}