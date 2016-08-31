match 'login_without_ichain', :to => 'account#login_without_ichain', :as => 'signin_without_ichain', :via => [:get, :post]
match 'logout_without_ichain', :to => 'account#logout_without_ichain', :as => 'signout_without_ichain', :via => [:get, :post]
