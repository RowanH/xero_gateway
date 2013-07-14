#

module XeroGateway
  class Item
    include Money
    
    attr_accessor :gateway

    TAX_TYPE = Account::TAX_TYPE unless defined?(TAX_TYPE)

    # Any errors that occurred when the #valid? method called.
    attr_reader :errors

    # All accessible fields
    attr_accessor :item_id, :code, :description, :sales_unit_price, :sales_account_code, :sales_tax_type, :purchase_unit_price, :purchase_account_code, :purchase_tax_type
        
    def initialize(params = {})
      @errors ||= []
      
      params.each do |k,v|
        self.send("#{k}=", v)
      end
    end
    
    # Validate the LineItem record according to what will be valid by the gateway.
    #
    # Usage: 
    #  line_item.valid?     # Returns true/false
    #  
    #  Additionally sets line_item.errors array to an array of field/error.
    def valid?
      @errors = []
      
      if !item_id.nil? && item_id !~ GUID_REGEX
        @errors << ['line_item_id', 'must be blank or a valid Xero GUID']
      end
      
      unless description
        @errors << ['description', "can't be blank"]
      end
            
      @errors.size == 0
    end

    def purchase_details?
      purchase_unit_price || purchase_account_code
    end

    def sales_details?
      sales_unit_price || sales_account_code
    end
    
    def to_xml(b = Builder::XmlMarkup.new)
      b.Item {
        b.Code code
        b.Description description
        b.ItemID item_id
        if purchase_details?
          b.PurchaseDetails {
            b.UnitPrice purchase_unit_price
            b.AccountCode purchase_account_code
          }
        end
        if sales_details?
          b.SalesDetails {
            b.UnitPrice sales_unit_price
            b.AccountCode sales_account_code
          }
        end
      }
    end
    
    def self.from_xml(item_element)
      item = Item.new
      item_element.children.each do |element|
        case(element.name)
          when "ItemID" then item.item_id = element.text
          when "Description" then item.description = element.text
          when "Code" then item.code = element.text
          when "PurchaseDetails"
            # Figre out nesting. 
            element.children.each do | element |
              item.purchase_unit_price = element.text if element.name == "UnitPrice"
              item.purchase_account_code = element.text if element.name == "AccountCode"
            end
          when "SalesDetails"
            # Figre out nesting. 
            element.children.each do | element |
              item.sales_unit_price = element.text if element.name == "UnitPrice"
              item.sales_account_code = element.text if element.name == "AccountCode"
            end
        end
      end
      item
    end    

    def ==(other)
      [:item_id, :code, :description, :sales_unit_price, :sales_account_code, :sales_tax_type, :purchase_unit_price, :purchase_account_code, :purchase_tax_type].each do |field|
        return false if send(field) != other.send(field)
      end
      return true
    end
  end  
end
