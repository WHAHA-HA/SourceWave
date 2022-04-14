# class StripeAnalytics
#
#   start_date = Chronic.parse('6/1/2015')
#   end_date = Chronic.parse('6/30/2015')
#   cohort_group = Subscription.using(:main_shard).where('created_at >= ? AND created_at <= ?', start_date, end_date).map(&:stripe_customer_token).reject{|t| !t.include?('cus')}
#   cohort = {}
#
#   cohort_group.map do |t|
#     begin
#       data = Stripe::Customer.retrieve(t).invoices.data
#       data_count = data.count
#       data.each_with_index do |d,i|
#         if d.paid == true
#           time = Time.at(d.date)
#           month = time.strftime("%B").downcase
#           cohort[month] = cohort[month].to_a.push([d.customer, d.paid, time])
#         end
#       end
#     rescue
#       nil
#     end
#   end
#
#   cohort
#
# end