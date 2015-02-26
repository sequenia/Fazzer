class User < ActiveRecord::Base
  devise :database_authenticatable,
         :registerable,
         # :recoverable,
         :rememberable,
         # :trackable,
         :validatable

  before_save :ensure_authentication_token

  validates :phone, :presence => true, :uniqueness => { :case_sensitive => false }

  has_many :auto_filters, dependent: :destroy
  has_many :devices, dependent: :destroy
  
  # Обновляет фильтр по переданным параметрам
  def update_or_create_filter(params)
    filter = first_filter
    if filter.nil?
      filter = AutoFilter.create({user_id: self.id})
    end

    attrs = {}
    AutoFilter.columns.each do |c|
      name = c.name
      if name != "created_at" && name != "updated_at" && name != "user_id" && name != "id"
        attrs[name] = params[name.to_sym]
      end
    end
    filter.update_attributes(attrs)
    filter
  end

  # Возвращает первый фильтр пользователя (и пока что единственный)
  def first_filter
    auto_filters.first
  end

  #########################################################################
  ## Реализация механизма авторизации
  #########################################################################
  def email_required?
    false
  end

  def email_changed?
    false
  end
 
  def ensure_authentication_token
    if authentication_token.blank?
      self.authentication_token = generate_authentication_token
    end
  end
 
  private
  
    def generate_authentication_token
      loop do
        token = Devise.friendly_token
        break token unless User.where(authentication_token: token).first
      end
    end
end
