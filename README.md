## Social API to Twitter, Facebook, Linkedin, Instagram and Pinterest using Devise, OmniAuth:
* Login while maintaining single User even if multiple emails associated with different social logins
* Gemset ruby-2.3.0@rails5.0.0.beta3 
* Ruby 2.3.0
* Rails 5.0.0.beta3

### References for this project
* basic app generated by template.rb (github.com/KudosX/template.rb)
* added gems:
```
gem 'devise'
gem 'therubyracer'
gem 'omniauth-facebook'
gem 'omniauth-twitter'
gem 'omniauth-linkedin'
gem 'omniauth-pinterest'
gem 'omniauth-instagram'
```
#### Followed the two below blog posts to complete project:
* http://blogs.nbostech.com/2015/08/loginregistration-social-signup-using-ruby-on-rails/
* http://blog.nbostech.com/2015/09/managing-multiple-providerssocial-login-with-existing-user-account-in-rails/

#### With the following as references as well:
* http://sourcey.com/rails-4-omniauth-using-devise-with-twitter-facebook-and-linkedin/
* https://gist.github.com/blairanderson/761ae067876930523482
* http://davidlesches.com/blog/clean-oauth-for-rails-an-object-oriented-approach
* https://github.com/davidlesches/clean-oauth-core/tree/master/app
* https://github.com/intridea/omniauth/wiki/Managing-Multiple-Providers
* http://www.sitepoint.com/rails-authentication-oauth-2-0-omniauth/
* https://github.com/intridea/omniauth/wiki/List-of-Strategies
* https://github.com/mohitjain/social-login-in-rails/tree/master/app
* https://github.com/arsduo/koala
* https://github.com/sferik/twitter
* https://github.com/arunagw/omniauth-twitter
* https://github.com/jot/omniauth-pinterest/
* https://launchschool.com/blog/facebook-graph-api-using-omniauth-facebook-and-koala
* http://snippets.aktagon.com/snippets/512-how-to-post-a-message-to-the-facebook-wall-with-omniauth-devise
* http://revelry.co/a-beginners-guide-to-using-the-facebook-api-in-your-rails-application-part-1/
* https://github.com/skorks/omniauth-linkedin

#### Getting therubyracer gem to work on mac:
```
brew install v8-315
bundle config --local build.libv8 --with-system-v8
bundle config --local build.therubyracer --with-v8-dir=/usr/local/opt/v8-315
bundle 
```

#### Step 1 - setup devise: 
```
rails g devise:install
rails g devise User
rake db:create
rake db:migrate
```
#### Step 2 - add action to not serve up pages until user authenticated:
add `before_action :authenticate_user!` to application_controller just before `end`

#### Step 3: to view routes
`rake routes` existing routes
- localhost:3000/users/sign_in
- localhost:3000/users/sign_up

#### Step 4: copy all devise views into application
`rails g devise:views` creates views/devise

#### Step 5 - update model to support OmniAuth:
- stop server, run `rails g migration AddColumnsToUsers provider uid first_name last_name`
- add `:default => nil` to :first_name and :last_name columns in migration
- then run `rake db:migrate`

#### Step 6 - add fields first_name, last_name to devise views
- add this code to views/devise/registrations/new.html.erb and edit.html.erb
- add just below `<div class="form-inputs">`
```
<div class="field">
  <%= f.label :first_name %><br />
  <%= f.text_field :first_name%>
</div> 
<div class="field">
  <%= f.label :last_name %><br />
  <%= f.text_field :last_name %>
</div>
```
#### Step 7 - tell the devise engine to permit newly created columns
- add logic to controllers/application_controller.rb just after before_action :authenticate_user!
```
before_action :configure_permitted_parameters, if: :devise_controller?
protected 
def configure_permitted_parameters
  devise_parameter_sanitizer.for(:sign_up) << [:first_name, :last_name]
end
```
#### Step 8 - get client ID(KEY) and SECRET from OAuth Service Providers
- https://dev.twitter.com/oauth/overview/application-owner-access-tokens
- https://apps.twitter.com to create your application
- below are the URL callbacks for the providers, can't use localhost but, IP address
- Facebook: http://localhost:3000/users/auth/facebook/callback
- Twitter: http://127.0.0.1:3000/users/auth/twitter/callback
- Linkedin: http://localhost:3000/users/auth/linkedin/callback
- Instagram: http://localhost:3000/users/auth/instagram/callback
- Pinterest: http://localhost:3000/users/auth/pinterest/callback

#### Step 9 - add ENVIRONMENT VARIABLES to .bash_profile on mac 
- for development mode only
- `nano .bash_profile` will open your bash file
- NOTE: close terminal to reset .bash_profile
```
export TWITTER_KEY="xxxxxkey_from_twitter_apixxxxxx"
export TWITTER_SECRET="xxxxxxsecret_from_twitter_apixxxxxx"
```

#### Step 10 - add ENVIRONMENT VARIABLES to devise.rb, just before end
```
config.omniauth :twitter, ENV["TWITTER_KEY"], ENV["TWITTER_SECRET"],
                 scope: 'public_profile,email', info_fields: 'id,email,name,link'
```

#### Step 11 - specify service provider in user.rb model and create new class
- add logic to models/user.rb, under class User
```
        :rememberable, :trackable, :validatable,
        :omniauthable, :omniauth_providers => [:twitter]
   def self.from_omniauth(auth)
     where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
       user.provider = auth.provider
       user.uid = auth.uid
       user.email = auth.info.email
       user.password = Devise.friendly_token[0,20]
     end
  end
```

#### Step 12 - edit routes.rb to specify name of controller that will handle callbacks
```
Rails.application.routes.draw do
  devise_for :users, :controllers => { :omniauth_callbacks => "callbacks" }
```

#### Step 13 - create new controllers/callbacks_controllers.rb and add this code
- each provider will need it's own method under CallbacksController class
```
class CallbacksController < Devise::OmniauthCallbacksController
  def twitter
    @user = User.from_omniauth(request.env["omniauth.auth"])
    sign_in_and_redirect @user
  end
end
```

#### Step 14 - refactor to separate user and oauth information
- create oauth model `rails g model authentication provider:string uid:string user_id:integer`
- modify authentication model as follows
```
class Authentication < ApplicationRecord
   belongs_to :user
   validates_presence_of :user_id, :uid, :provider
   validates_uniqueness_of :uid, :scope => :provider
   def provider_name
     provider.titleize
   end  
 end
```
- add to user.rb `has_many :authentications`
- remove oauth from table `rails g migration remove_provider_fileds_from_user`
- add code to RemoveProvider migration
```
def change
    remove_column :users, :provider
    remove_column :users, :uid
end
```
- run `rake db:migrate`

#### Step 15 - collapse signup and signin process into single step
- when user signs in, look for existing authorizations for that external account
- create a user if no authorization is found
- add an authorization to an existing user if user is already logged in
- create controller `rails g controller authentications`
- add the following code to authentication_controller.rb to look like this
```
class AuthenticationsController < ApplicationController
 def index
   @authentications = current_user.authentications if current_user
 end
 def create
   omniauth = request.env["omniauth.auth"]
   authentication = Authentication.find_by_provider_and_uid(omniauth['provider'], omniauth['uid'])
   if authentication
     flash[:notice] = "Signed in successfully."
     sign_in_and_redirect(:user, authentication.user)
   elsif current_user
     current_user.authentications.create!(:provider => omniauth['provider'], :uid => omniauth['uid'])
     flash[:notice] = "Authentication successful."
     redirect_to authentications_url
   else
     user = User.new
     user.apply_omniauth(omniauth)
     if user.save
       flash[:notice] = "Signed in successfully."
       sign_in_and_redirect(:user, user)
     else
       session[:omniauth] = omniauth.except('extra')
       redirect_to new_user_registration_url
     end
   end
 end
 def destroy
   @authentication = current_user.authentications.find(params[:id])
   @authentication.destroy
   flash[:notice] = "Successfully destroyed authentication."
   redirect_to authentications_url
 end
end
```
- add methods to the user.rb model just below has_many
```
 has_many :authentications
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
```  
 
- create views/authentications/index.html.erb that will show number of authentications of user
- add the following code to authentications/index.html.erb
```
<% "Sign In Options" %>
<% if @authentications %>
  <% unless @authentications.empty? %>
    <p><strong>You have linked these services with your account:</strong></p>
    <div class="authentications">
      <% for authentication in @authentications %>
        <div class="authentication">
          <%= image_tag "#{authentication.provider}_icon.png", size: "32x32"%>
          <div class="provider"><%= authentication.provider_name %></div>
          <div class="uid"><%= authentication.uid %></div>
          <%= link_to "X", authentication, :confirm => 'Are you sure you want to remove this authentication option?', :method => :delete, :class => "remove" %>
        </div>
      <% end %>
      <div class="clear"></div>
    </div>
  <% end %>
<% else %>
  <p><strong>Sign in through one of these services:</strong></p>
<% end %>
<p><strong>Add another service to sign in with:</strong></p>
  <%- current_user.class.omniauth_providers.each do |provider| %>
    <%- if !current_user.existing_auth_providers.include?(provider.to_s) %>
      <%= link_to omniauth_authorize_path(current_user.class, provider) do %>
          <%= image_tag "#{provider.to_s}_icon.png", size: "32x32" %>
      <% end %>
    <% end %>
  <% end -%>
<div class="clear"></div>
<% unless user_signed_in? %>
  <p>
    <strong>Don't use these services?</strong>
    <%= link_to "Sign up", new_user_registration_path %> or
    <%= link_to "sign in", new_user_session_path %> with a password.
  </p>
<% end %> 
```
#### Step 16 - override the devise registration controller
- create a registration controller and update code
- copy devise registrations views (create, edit) and change code
- tell devise routes to use our registrations controller instead of its own controller
- update the callback controller logic same as authentication controller
- create registrations controller `rails g controller registrations`
- add the following code to registrations_controller.rb
```
class RegistrationsController < Devise::RegistrationsController
  def create
    super
    session[:omniauth] = nil unless @user.new_record?
  end
  private
  def build_resource(*args)
    super
    if session[:omniauth]
      @user.apply_omniauth(session[:omniauth])
      @user.valid?
    end
  end
end
```
- copy views/devise/registrations to views/registrations
- update the code in views/registrations/new.html.erb as follows
```
<div class="border-form-div">
<h2>Sign up</h2>
<%= form_for(resource, :as => resource_name, :url => registration_path(resource_name)) do |f| %>
  <%= devise_error_messages! %>
  <p><%= f.label :email %><br />
  <%= f.text_field :email %></p>
<% if @user.password_required? %>
  <p><%= f.label :password %><br />
  <%= f.password_field :password %></p>
  <p><%= f.label :password_confirmation %><br />
  <%= f.password_field :password_confirmation %></p>
<% end %>
  <p style="text-align: center;"><%= f.submit "Sign up", :class => 'btn_login' %></p>
<% end %>
<%= render :partial => "devise/shared/links" %>
</div>
```

- update the code in views/registrations/edit.html.erb as follows
```
<div class="border-form-div">
<%= form_for(resource, :as => resource_name, :url => registration_path(resource_name), :html => { :method => :put, :class => "edit_user_form"}) do |f| %>
  <%= devise_error_messages! %>
  <p><%= f.label :email %><br />
  <%= f.text_field :email %></p>
  <p><%= f.label :password %> <i>(leave blank if you don't want to change it)</i><br />
  <%= f.password_field :password %></p>
  <p><%= f.label :password_confirmation %><br />
  <%= f.password_field :password_confirmation %></p>
  <p><%= f.label :current_password %> <i>(we need your current password to confirm your changes)</i><br />
  <%= f.password_field :current_password %></p>
  <p style="text-align: center;"><%= f.submit "Update", {:class => "btn_login"} %></p>
<% end %>
<p>Unhappy? <%= link_to "Cancel my account", registration_path(resource_name), :confirm => "Are you sure?", :method => :delete %>.</p>
<%= link_to "Back", :back %>
</div>
```

#### Step 17 - update routes.rb and callback controller
- add to routes.rb to make it look like
```
devise_for :users, :controllers => { :registrations => 'registrations', :omniauth_callbacks => "callbacks"}
post '/auth/:provider/callback' => 'authentications#create'
```
- make callbacks_controller.rb look like the following
```
class CallbacksController < Devise::OmniauthCallbacksController
  def all
    omniauth = request.env["omniauth.auth"]
    authentication = Authentication.find_by_provider_and_uid(omniauth['provider'], omniauth['uid'])
    if authentication
      flash[:notice] = "Signed in successfully."
      sign_in_and_redirect(:user, authentication.user)
    elsif current_user
      current_user.authentications.create!(:provider => omniauth['provider'], :uid => omniauth['uid'])
      flash[:notice] = "Authentication successful."
      redirect_to authentications_url
    else
      user = User.new
      user.apply_omniauth(omniauth)
      if user.save
        flash[:notice] = "Signed in successfully."
        sign_in_and_redirect(:user, user)
      else
        session[:omniauth] = omniauth.except('extra')
        redirect_to new_user_registration_url
      end
    end
  end
  alias_method :facebook, :all
  alias_method :twitter, :all
end
```

#### Step 18 - added validation for lack of email from twitter to user.rb model
- add to class: `validates :email, presence: true, unless: :twitter?`
- add method to user.rb: 
```
def twitter?
self.provider == 'twitter'
end
```
- refactored user.rb, def self.from_omniauth(auth) method and looks like:
```
user.password = Devise.friendly_token[0,20]
      user.save
      user
    end
```
    