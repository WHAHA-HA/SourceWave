class User < ActiveRecord::Base
  after_create :create_user_dashboard
  before_create { generate_token(:auth_token) }
  before_create :downcase

  has_secure_password

  validates_uniqueness_of :email

  validates :email, presence: true

  has_one :user_dashboard
  has_one :subscription
  has_many :crawls
  has_many :sites, through: :crawls
  has_many :pages, through: :sites
  has_many :gather_links_batches, through: :sites
  has_many :process_links_batches, through: :sites
  has_many :heroku_apps, through: :crawls
  
  def self.admin_search(query)
    if query.present?
      where("email ilike :q", q: "%#{query}%")
    else
      all
    end
  end
  
  def send_password_reset
    generate_token(:password_reset_token)
    self.password_reset_sent_at = Time.zone.now
    save!
    UserMailer.password_reset(self).deliver
  end
  
  def downcase
    self.email = self.email.downcase
  end
  
  def generate_token(column)
    begin
      self[column] = SecureRandom.urlsafe_base64
    end while User.exists?(column => self[column])
  end

  def subscribed?
    subscription.present?
  end

  def admin
    true
  end

  def is_admin?
    emails = ['alex@test.com', 'batman34@gmail.com', 'gregoryortiz@mac.com', 'ven.inova303@gmail.com']
    emails.include?(self.email)
  end

  def active?
    subscribed? ? subscription.status == 'active' : false
  end
  
  def has_basic_subscription?
    subscribed? ? subscription.plan_name == 'basic' : false
  end

end
