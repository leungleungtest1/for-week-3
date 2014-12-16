class SessionsController < ApplicationController
  def new
    redirect_to home_path if current_user  
  end
  def create
    @categories = Category.all
    @user = User.find_by(email: params[:email])
    if !!@user && @user.authenticate(params[:password])
    session[:user_id] = @user.id
    flash[:success] = 'You signed in successfully.'
    redirect_to home_path
    else
      flash.now[:danger] = "There are some wrong in emails or password."
      render 'sessions/new'
    end
  end

  def destroy
    session[:user_id] = nil
    flash[:success] = "you are signed out."
    redirect_to root_path
  end
end