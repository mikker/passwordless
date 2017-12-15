# frozen_string_literal: true

class RegistrationsController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.create params.require(:user).permit(:email)

    if @user.save
      sign_in @user
      redirect_to root_path
    else
      render :new
    end
  end
end
