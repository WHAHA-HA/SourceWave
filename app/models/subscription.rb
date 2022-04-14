class Subscription < ActiveRecord::Base
  belongs_to :user
  belongs_to :plan

  attr_accessor :stripe_card_token
  attr_accessor :stripe_plan_id
  attr_accessor :trial_end

  validates_presence_of :stripe_customer_token, :message => 'Stripe Error'
  validates :plan, :presence => true
  validates :user, :uniqueness => true

  def save_with_stripe!(stripe_plan = (stripe_plan_id.present? ? stripe_plan_id : false ) || plan_id)
    # It has dynamic stripe plan variable if it exists either set
    # through controller or already on user or passed on call
    # which allows us to use it as upgrade as well.

    valid_params = (user.email && stripe_plan_id.present? && stripe_card_token.present?)

    if valid_params

      params = {
        email: user.email,
        plan: stripe_plan_id,
        card: stripe_card_token,
        trial_end: (trial_end.to_i.days.from_now.to_time.to_i if trial_end.present?),
        coupon: (coupon if coupon.present?)
      }.reject{|k,v|v.nil?}

      customer = Stripe::Customer.create(params)

      # Create customer and Set Card
      # if trial_end.to_i == 0
      #   customer = Stripe::Customer.create(email: user.email, plan: stripe_plan_id, card: stripe_card_token)
      # else
      #   customer = Stripe::Customer.create(email: user.email, plan: stripe_plan_id, card: stripe_card_token, trial_end: trial_end.to_i.days.from_now.to_time.to_i)
      # end

      # customer.subscriptions.create(plan: stripe_plan)

      # Save Plan, Status and Customer Token
      self.update!(status: 'active', stripe_customer_token: customer.id)

    else

      return false

    end

  end

  def subscribe_with_stripe(options={})

    customer = Stripe::Customer.retrieve(stripe_customer_token)

    params = {
      plan: stripe_plan_id,
      trial_end: (options['trial_end'].to_i.days.from_now.to_time.to_i if options['trial_end'].present?),
      coupon: (options['coupon'] if options['coupon'].present?)
    }.reject{|k,v|v.nil?}

    sub = customer.subscriptions.create(params)

    # if options['trial_end'].to_i == 0
    #   sub = customer.subscriptions.create(plan: stripe_plan_id)
    # else
    #   sub = customer.subscriptions.create(plan: stripe_plan_id, trial_end: options['trial_end'].to_i.days.from_now.to_time.to_i)
    # end

    if sub[:status] == 'active'
      self.update(status: 'active', plan: Plan.find_by_name(stripe_plan_id), cancel_date: nil)
    end

  end

  def unsubscribe_with_stripe
    customer = Stripe::Customer.retrieve(stripe_customer_token)
    sub_id = customer.subscriptions.data.find{|sub| sub[:plan][:id] == plan_id.to_s}[:id]
    delete = customer.subscriptions.retrieve(sub_id).delete(at_period_end: true)
    self.update(cancel_date: Time.at(delete[:current_period_end]).to_datetime)
  end

  def cancel_subscription
    self.update(status: 'canceled')
  end

  def set_failed
    self.update(failed_transaction: true)
  end

  def upgrade_to_plan(new_plan_id, credit_card_details = {})
    customer = Stripe::Customer.retrieve(stripe_customer_token)
    sub_id = customer.subscriptions.data.find{|sub| sub[:plan][:id] == plan_id.to_s}[:id]
    sub = customer.subscriptions.retrieve(sub_id)
    sub.plan = new_plan_id.to_s
    if !credit_card_details.empty?
      sub.source = {
        'object' => "card",
        'number' => credit_card_details[:number].to_s,
        'exp_month' => credit_card_details[:month],
        'exp_year' =>credit_card_details[:year],
        'cvc' => credit_card_details[:cvc]
      }.reject{|k,v|v.nil?}
    end
    sub.save
    if sub[:plan][:id] == new_plan_id.to_s
      self.update(plan_id: new_plan_id.to_i, status: 'active', failed_transaction: false, cancel_date: nil)
    end
  end

  def active?
    case status
      when 'active'
        true
      when 'canceled' || 'cancelled'
        false
      else
        false
    end
  end

end
