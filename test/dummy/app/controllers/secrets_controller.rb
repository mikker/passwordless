# frozen_string_literal: true

class SecretsController < ApplicationController
  before_action :authenticate_user!

  def index
    render plain: "shhhh! secrets!"
  end
end
