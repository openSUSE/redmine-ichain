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
            redirect_to RedmineIChain.setting("base_url") + "/ICSLogin/auth-up/?url=" + request.original_url
          else
            extra_attributes = RedmineIChain.extra_user_attributes(request)
            if RedmineIChain.match_also_by_mail?
              # First try by login, then by mail and finally create a new user
              user = User.find_by_login(proxy_user)
              user ||= User.find_by_mail(extra_attributes["mail"]) unless extra_attributes["mail"].blank?
              if user.nil?
                # Mass-assignment of User#login is not allowed
                user = User.new
                user.login = proxy_user
              end
            else
              user = User.find_or_initialize_by_login(proxy_user)
            end
            if user.new_record?
              if RedmineIChain.auto_create_users?
                user.attributes = extra_attributes
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
                if RedmineIChain.auto_update_users?
                  user.login = proxy_user
                  user.attributes = extra_attributes
                  user.save
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
      if RedmineIChain.enabled? && !RedmineIChain.fake? && RedmineIChain.logout_of_ichain_on_logout?
        logout_user
        redirect_to RedmineIChain.setting("base_url") + "/cmd/ICSLogout/"
      else
        logout_without_ichain
      end
    end
  end
end
