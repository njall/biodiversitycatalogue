require 'digest/sha1'

class User < ActiveRecord::Base
  
  validates_presence_of       :email
  validates_presence_of       :password, :if => :password_required?
  validates_presence_of       :password_confirmation, :if => :password_required?
  validates_confirmation_of   :password, :if => :password_required?
  validates_confirmation_of   :email
  validates_uniqueness_of     :email, :case_sensitive => false
  validates_email_veracity_of :email
  
  attr_protected  :id, :salt, :crypted_password, :activated_at, :security_token, :role_id
  attr_accessor   :password
  before_save     :encrypt_password
  before_create   :generate_activation_code, :generate_default_display_name #before_save messes up with users:activate_account
  
  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password)
    return nil if login.blank? or password.blank?
    
    # Check for a User with email matching 'login'
    u = find(:first, :conditions => ["email = ?", login])
    
    u && u.activated? && u.authenticated?(password) ? u : nil
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end
    
  def activated?
    self.activated_at != nil
  end
  
   def password_required?
     crypted_password.blank? || !password.blank?
   end
   
  private
  # Encrypts password with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end
  
  # 
  def encrypt_password
    return if password.blank?
    self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{email}--") if self.salt.nil?
    self.crypted_password = encrypt(password)
  end
  
  # Encrypts the password with the user salt
  def encrypt(password)
    e = self.class.encrypt(password, salt)
    
    # Clear password virtual attribute to prevent it from being shown in forms after update
    self.password = nil
    self.password_confirmation = nil #if self.respond_to?(password_confirmation)
    return e
  end
  
  # Generate the confirmation key sent by email to activate an account
  def generate_activation_code
    self.security_token = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{email}--#{salt}--")
  end
  
  # Generate a default display name when creating a user for the 1st time
  def generate_default_display_name
    self.display_name = email.split("@")[0]
  end
end