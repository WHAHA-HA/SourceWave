class PaypalCheckout
  
  def initialize seller_email, domain_id, price, return_url
    @values = {
      :business => seller_email,
      :cmd => '_cart',
      :upload => 1,
      :return => return_url,
      :invoice => domain_id + Time.now.to_i,
      'amount_1' => price,
      'item_name_1' => 'Source Revive Domain'
    }
    
  end
  
  def url
    if Rails.env == 'production'
      "https://www.paypal.com/cgi-bin/webscr?" + @values.to_query      
    else
      "https://www.sandbox.paypal.com/cgi-bin/webscr?" + @values.to_query      
    end

  end
  
end