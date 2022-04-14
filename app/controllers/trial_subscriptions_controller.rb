class TrialSubscriptionsController < ApplicationController
  
  def new
    
    @subscription = Subscription.new
    if params['plan_id'] == "1"
      @price = '199.00'
    else
      @price = '297.00'
    end
    
    render layout: 'checkout'
    
  end

  def create
    @user = User.using(:main_shard).create(params[:user].permit(:email, :password, :password_confirmation, :first_name, :last_name, :address_1, :address_2, :city, :state, :zip, :country))
    plan = Plan.using(:main_shard).find(params['plan_id'].to_i)
    @user.minutes_available = plan.minutes_per_month.to_f
    
    p "the user id is #{@user.id}"
    
    if @user
      cookies[:auth_token] = @user.auth_token
    end
    
    p "the stripe card token is #{params['stripeToken']}"
    p "the stripe card token is #{subscription_params[:stripeToken]}"

    @subscription = Subscription.using(:main_shard).new(user_id: @user.id, stripe_card_token: subscription_params[:stripeToken])
    
    p "the subscription id is #{@subscription.id}"
    
    # Plan
    @subscription.plan = plan

    # User Info
    user_params = subscription_params[:user]

    # Set stripe stuff.
    @subscription.stripe_plan_id = subscription_params[:plan_id]
    @subscription.stripe_card_token = subscription_params[:stripeToken]
    @subscription.trial_end = subscription_params[:trial_end].to_s
    @subscription.coupon = subscription_params[:coupon].to_s

    respond_to do |format|

      if plan.present? && @subscription.save_with_stripe!
        # After Successful billing update stripe user with billing details if they are present
        @user.update(user_params)
        format.html { redirect_to '/dashboard', flash:{success: 'Trial Subscription Successful. Welcome to Revive!' } }
      elsif plan.present? == false
        format.html { redirect_to trial_subscriptions_new_path, flash:{error: 'Invalid Plan ID' } }
      else
        format.html { render action: :new, layout: 'checkout' }
      end

    end
    
  end
  
  def subscription_params
    params.permit(:stripeToken, :plan_id, :trial_end, :coupon, {user:[:first_name, :last_name, :phone, :email, :address_1, :address_2, :city, :zip, :state, :country, :password, :password_confirmation]}, {card:[:number, :cvc, :month, :year]})
  end
  
end
