class SubscriptionsController < ApplicationController
  before_action :authorize, except: [:new_basic, :create_basic, :cancel_webhook, :charge_failure_webhook]
  before_action :set_subscription, only: [:show, :edit, :update, :destroy, :upgrade_subscription, :upgrade_subscription_with_card]

  def index
  end

  def cancel_webhook
    @subscription = Subscription.using(:main_shard).where(stripe_customer_token: params[:data][:object][:customer]).first
    @subscription.cancel_subscription
    render nothing: true
  end

  def charge_failure_webhook
    @subscription = Subscription.using(:main_shard).where(stripe_customer_token: params[:data][:object][:customer]).first
    @subscription.set_failed
    render nothing: true
  end

  def new
    @subscription = Subscription.new
    # if params['plan_id'] == "1"
    #   @price = '199.00'
    # else
    #   @price = '297.00'
    # end

    @price = Plan.using(:main_shard).find_by_name(subscription_params[:plan_id].to_s).price.to_s
    # For ~> checkout
    # If the user already has a plan just redirect to dash
    # in the future this will redirect to account and billing.

    if !current_user.subscription.nil? && current_user.subscription.active? && !current_user.subscription.failed_transaction?
      redirect_to '/account#subscription'
    else
      render layout: 'checkout'
    end

    # render layout: 'checkout'

  end

  # New Stripe Subscription
  def create
    @subscription = Subscription.new(user: current_user, stripe_card_token: params['stripeToken'])

    # Plan
    plan = Plan.using(:main_shard).find_by_name(subscription_params[:plan_id].to_s)
    @subscription.plan = plan

    # User Info
    user_params = subscription_params[:user]

    # Set stripe stuff.
    @subscription.stripe_plan_id = subscription_params[:plan_id]
    @subscription.stripe_card_token = subscription_params[:stripeToken]
    @subscription.trial_end = subscription_params[:trial_end].to_i unless subscription_params[:trial_end].empty?

    respond_to do |format|

      if plan.present? && @subscription.save_with_stripe!
        # After Successful billing update stripe user with billing details if they are present
        # @subscription.user.update(user_params) if user_params.present?
        @subscription.user.update(user_params)
        format.html
      elsif plan.present? == false
        format.html { redirect_to new_subscriptions_path, flash:{error: 'Invalid Plan ID' } }
      else
        format.html { render action: :new, layout: 'checkout' }
      end

    end

  end

  def new_basic
    @subscription = Subscription.new

    render layout: 'checkout'

  end

  def create_basic
    # raise
    # User Info
    user_params = subscription_params[:user]

    @user = User.using(:main_shard).create(params[:user].permit(:email, :password, :password_confirmation))
    plan = Plan.using(:main_shard).find(params['plan_id'].to_i)

    p "the user id is #{@user.id}"

    @user.minutes_available = plan.minutes_per_month.to_f

    if @user
      cookies[:auth_token] = @user.auth_token
    end

    @subscription = Subscription.using(:main_shard).new(user_id: @user.id, stripe_customer_token: '0', plan_id: plan.id, plan_name: 'basic')

    p "the subscription id is #{@subscription.id}"

    # Plan
    # @subscription.plan = plan

    respond_to do |format|
      if plan.present? && @subscription.save
        format.html { redirect_to '/dashboard', flash:{success: 'Welcome to Revive!' } }
      elsif plan.present? == false
        format.html { redirect_to new_basic_subscription_path, flash:{error: 'Invalid Plan ID' } }
      else
        format.html { render action: :new_basic, layout: 'checkout' }
      end
    end

  end

  def upgrade_card_details
    @price = Plan.using(:main_shard).find_by_name(subscription_params[:plan_id].to_s).price.to_s

    render layout: 'checkout'
  end

  # Re subscribe Stripe
  def update
    @subscription.stripe_plan_id = subscription_params[:plan_id] ||  @subscription.plan.name

    respond_to do |format|
      if @subscription.user == current_user && @subscription.subscribe_with_stripe
        format.html { redirect_to '/dashboard', flash:{success: 'Subscription Successful. Welcome to Back Revive!' } }
      else
        format.html { redirect_to '/account#subscription'}
      end
    end
  end

  # Unsubscribe From Stripe

  def destroy
    respond_to do |format|
      if @subscription.unsubscribe_with_stripe
        format.html { redirect_to dashboard_path, flash:{success: 'Successfully Canceled Subscription. Your subscription will expire at the end of the billing cycle. \n We will miss you ' + "#{current_user.first_name}! :(" }}
      else
        format.html { redirect_to dashboard_path,  flash:{success: 'Subscription Cancel Failed.'} }
      end
    end
  end

  def upgrade_subscription
    respond_to do |format|
      if @subscription.upgrade_to_plan(params['plan_id'])
        format.html { redirect_to dashboard_path, flash:{success: 'Successfully Upgraded Subscription. BOOM :)' }}
      else
        format.html { redirect_to dashboard_path,  flash:{success: 'Subscription Upgrade Failed.'} }
      end
    end
  end

  def upgrade_subscription_with_card
    respond_to do |format|
      if @subscription.upgrade_to_plan(params['plan_id'], subscription_params[:card])
        format.html { redirect_to dashboard_path, flash:{success: 'Successfully updated credit card details.' }}
      else
        format.html { redirect_to dashboard_path,  flash:{success: 'Subscription Failed.'} }
      end
    end
  end

  def create_trial_for_existing_customer
    if current_user.subscription && current_user.subscription.stripe_customer_token
      begin
        customer = Stripe::Customer.retrieve(current_user.subscription.stripe_customer_token)
        if customer
          customer.subscriptions.create(:plan => params['plan_id'], trial_end: params['trial_end'].to_i.days.from_now.to_time.to_i)
          current_user.subscription.status = 'active'
          current_user.subscription.trial_end = "#{params['trial_end'].to_i.days.from_now.to_time.to_i}"
          current_user.subscription.save
        end
        redirect_to dashboard_path, flash:{success: 'Subscription Successful. Welcome Back to Revive!' }
      rescue
        redirect_to dashboard_path, flash:{error: 'Subscription Unsuccessful' }
      end
    end

  end

  private

  def set_subscription
    @subscription = current_user.subscription
  end

  # Strong Params;
  # Never Trust Anything From The Pesky Interwebs for Users Are Cunning And [REDACTED]

  def subscription_params
    params.permit(:stripeToken, :plan_id, :trial_end, {user:[:first_name, :last_name, :phone, :email, :address_1, :address_2, :city, :zip, :state, :country, :password, :password_confirmation]}, {card:[:number, :cvc, :month, :year]})
  end

end
