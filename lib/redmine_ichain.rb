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

  def enabled?
    setting("enabled") == "true"
  end

  def fake?
    setting("fake_ichain_server") == "true"
  end

  def extra_user_attributes
    attrs = {}
    if fake?
      setting("fake_auto_user_attributes_map").scan(/((\w+)=([^&]+))&?/) do |match|
        attrs[match[1]] = match[2]
      end
    else
      setting("auto_user_attributes_map").scan(/((\w+)=([^&]+))&?/) do |match|
        attrs[match[1]] = ActionDispatch::Request.env[match[2]]
      end
    end
    attrs
  end
end
