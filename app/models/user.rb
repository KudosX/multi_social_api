class User < ApplicationRecord
  has_many :authentications

  validates :email, presence: true, unless: :twitter?
  validates :email, presence: true, unless: :facebook?

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, :omniauth_providers => [:twitter, :facebook, :linkedin, :instagram]


  def apply_omniauth(omniauth)
    authentications.build(:provider => omniauth['provider'], :uid => omniauth['uid'])
  end

  def password_required?
    (authentications.empty? || !password.blank?) && super
  end

  def existing_auth_providers
    ps = self.authentications.all

    if ps.size > 0
      return ps.map(&:provider)
    else
      return []
    end
  end

  def provider

  end

  def twitter?
    self.provider == 'twitter'
  end

  def facebook?
    self.provider == 'facebook'
  end

  def linkedin?
    self.provider == 'linkedin'
  end

  def instagram?
    self.provider == 'instagram'
  end

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.provider = auth.provider
      user.uid = auth.uid
      user.email = auth.info.email
      user.password = Devise.friendly_token[0,20]
    end
  end
end

# validates :email, presence: false
# validates :email, confirmation: false
# User.create(email: nil).valid? # => true
# validates :email, absence: true
# validates :email, allow_nil: true
# validates :email, absence: true, if: "email.nil?"
# validates :email,
