module ApplicationControllerPatch
  def self.included(base)
    base.send(:include, InstanceMethods)
    base.class_eval do
      alias_method_chain :find_current_user, :ichain
    end
  end

  module InstanceMethods
    def find_current_user_with_ichain
      user = nil
      if RedmineIChain.enabled? && session[:user_id].nil? && (proxy_user = request.env[RedmineIChain.setting("username_header")])
        user = (User.active.where(:login => proxy_user).first rescue nil)
      end
      user || find_current_user_without_ichain
    end
  end
end
