class AdminsController < ApplicationController
  before_filter :is_admin?

  def index
    @users = User.admin_search(params[:query]).order('created_at DESC').page(params[:page]).per_page(25)
    @maintenance = Maintenance.first
  end

  def become_user
    user = User.find_by id: params[:user_id]
    cookies.delete(:auth_token)
    cookies.permanent[:auth_token] = user.auth_token
    redirect_to root_url
  end

  def edit_user
    @user = User.find_by id: params[:user_id]
  end

  def new_user
    @user = User.new
  end

  def update_user
    user = User.find_by id: params[:user][:user_id]
    if user.update_attributes user_params
      flash[:notice] = "#{user.email} has been updated."
      redirect_to admins_path
    else
      flash[:error] = 'There was a problem updating.'
    end
  end

  def create_user
    @user = User.using(:main_shard).new(params[:user].permit(:email, :password, :password_confirmation))
    plan = Plan.using(:main_shard).find_by_name(params[:plan_id].to_i)
    @user.minutes_available = plan.minutes_per_month.to_f
    if @user.save
      @subscription = Subscription.using(:main_shard).new(
                        user_id: @user.id,
                        stripe_customer_token: '0',
                        plan_id: plan.id,
                        plan_name: 'basic',
                        status: 'active'
                      )
      @subscription.save
      flash[:notice] = "User has been created with a free plan!"
    else
      flash[:notice] = "There was an error creating the user!"
    end
    redirect_to admins_path
  end

  def maintenance
    @maintenance = Maintenance.using(:main_shard).find params[:maintenance][:id]
    @maintenance.update_attributes maintenance_params
    message = "Maintenance message has been "
    message += params[:maintenance][:enabled] == '1' ? "enabled" : "disabled"
    flash[:notice] = message
    redirect_to admins_path
  end

  def make_user_active
    Api.toggle_user_status(user_id: params[:user_id], status: 'make_active')
    user = User.using(:main_shard).find_by id: params[:user_id]
    flash[:notice] = "#{user.email} has been made active"
    redirect_to admins_path
  end

  def make_user_inactive
    Api.toggle_user_status(user_id: params[:user_id], status: 'make_inactive')
    user = User.using(:main_shard).find_by id: params[:user_id]
    flash[:notice] = "#{user.email} has been deactivated"
    redirect_to admins_path
  end

  private

  def is_admin?
    redirect_to dashboard_path, alert: "Not authorized" unless current_user.admin
  end

  def user_params
    params.require(:user).permit(:email, :minutes_used, :password, :password_confirmation)
  end

  def maintenance_params
    params.require(:maintenance).permit(:enabled, :message, :id)
  end

end
