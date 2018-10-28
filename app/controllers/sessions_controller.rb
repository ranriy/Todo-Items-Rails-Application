class SessionsController < ApplicationController
  skip_before_action :ensure_login, only: [:new, :create]

  def new
  end

  def create
  	user=User.find_by(username: params[:user][:username])
		if user && user.authenticate(params[:user][:password])
			session[:user_id] = user.id
			return redirect_to root_path, notice: "Logged in successfully" 
		end
		flash[:errors] = 'Incorrect email or username'
		redirect_to login_path
  end

  def destroy
  	session[:user_id] = nil
  	redirect_to login_path, notice: "Successful Logout"
  end
end
