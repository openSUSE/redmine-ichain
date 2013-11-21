require 'redmine'

module RedmineIChain
  extend self

  def plugin
    Redmine::Plugin.find(:redmine_ichain)
  end

  def settings
    if ActiveRecord::Base.connection.table_exists?(:settings) && self.plugin && Setting.plugin_redmine_ichain
      Setting.plugin_redmine_ichain
    else
      plugin.settings[:default]
    end
  end

  def setting(name)
    settings && settings.has_key?(name) && settings[name] || nil
  end

  # For checking the configuration flags in a more convenient way
  def method_missing(meth, *args, &block)
    if meth.to_s =~ /^(\w*)\?$/
      if %w(auto_create_users auto_update_users enabled fake_ichain_server keep_standard_login logout_of_ichain_on_logout match_also_by_mail).include? $1
        setting($1) == "true"
      else
        super
      end
    else
      super
    end
  end

  def fake?
    fake_ichain_server?
  end

  def extra_user_attributes(request)
    attrs = {}
    if fake?
      setting("fake_auto_user_attributes_map").scan(/((\w+)=([^&]+))&?/) do |match|
        attrs[match[1]] = match[2]
      end
    else
      setting("auto_user_attributes_map").scan(/((\w+)=([^&]+))&?/) do |match|
        attrs[match[1]] = request.env[match[2]]
      end
    end
    attrs
  end
end
