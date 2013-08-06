module AccountControllerPatch
  def self.included(base)
    base.send(:include, InstanceMethods)
    base.class_eval do
      alias_method_chain :login, :ichain
      alias_method_chain :logout, :ichain
    end
  end

  module InstanceMethods
    def login_with_ichain
      if params[:username].blank? && params[:password].blank? && RedmineIChain.enabled?
        if session[:user_id].blank?
          if RedmineIChain.fake?
            proxy_user = RedmineIChain.setting("fake_username")
          else
            proxy_user = request.env[RedmineIChain.setting("username_header")]
          end
          if proxy_user.blank?
            redirect_to RedmineIChain.setting("base_url") + "/ICSLogin/auth-up"
          else
            user = User.find_or_initialize_by_login(proxy_user)
            if user.new_record?
              if RedmineIChain.setting("auto_create_users") == "true"
                user.attributes = RedmineIChain.extra_user_attributes(request)
                user.status = User::STATUS_REGISTERED
                register_automatically(user) do
                  onthefly_creation_failed(user)
                end
              else
                render_error(
                  :message => l(:ichain_user_not_found, :user => proxy_user),
                  :status => 401
                )
              end
            else
              if user.active?
                if RedmineIChain.setting("auto_update_users") == "true"
                  user.update_attributes RedmineIChain.extra_user_attributes(request)
                end
                successful_authentication(user)
              else
                render_error(
                  :message => l(:ichain_user_not_found, :user => proxy_user),
                  :status => 401
                )
              end
            end
          end
        end
      else
        login_without_ichain
      end
    end

    def logout_with_ichain
      if RedmineIChain.enabled? && !RedmineIChain.fake? && RedmineIChain.setting("logout_of_ichain_on_logout") == "true"
        logout_user
        redirect_to RedmineIChain.setting("base_url") + "/ICHAINLogout"
      else
        logout_without_ichain
      end
    end
  end
end
