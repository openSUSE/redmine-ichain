require 'redmine_ichain'
require 'account_controller_patch'
require 'application_controller_patch'

Redmine::Plugin.register :redmine_ichain do
  name 'Redmine iChain plugin'
  author 'Ancor Gonzalez Sosa'
  description 'This is a plugin for Redmine 2+ enabling authentication through iChain. Strongly inspired by https://github.com/brandonaaron/redmine_rubycas/ (thanks Brandon).'
  version '0.0.3'
  url ''
  author_url ''

  requires_redmine :version_or_higher => '2.3.1'

  menu(:account_menu, :login_without_ichain, { :controller => "account", :action => "login_without_ichain" },
    :caption => :login_without_ichain, :after => :login,
    :if => Proc.new { RedmineIChain.enabled? && RedmineIChain.setting("keep_standard_login") == "true" && !User.current.logged? })

  settings(:partial => 'settings/redmine_ichain_settings', :default => {
    # plugin settings
    :enabled => false,
    :keep_standard_login => true,
    :auto_create_users => false,
    :auto_update_users => false,
    :auto_user_attributes_map => 'firstname=HTTP_X_FIRSTNAME&lastname=HTTP_X_LASTNAME&mail=HTTP_X_EMAIL',
    :logout_of_ichain_on_logout => true,
    # ichain client config settings
    :base_url => "https://yourserver.com",
    :username_header => 'HTTP_X_USERNAME',
    :fake_ichain_server => false,
    :fake_username => "johndoe",
    :fake_auto_user_attributes_map => "firstname=John&lastname=Doe&mail=jdoe@example.com"
  })
end

ActionDispatch::Callbacks.to_prepare do
  # Patch account controller
  require_dependency 'account_controller'
  AccountController.send(:include, AccountControllerPatch)
  # Patch application controller
  require_dependency 'application_controller'
  ApplicationController.send(:include, ApplicationControllerPatch)
end
